package WebService::GrowthBook;
# ABSTRACT: ...

use strict;
use warnings;
no indirect;
use feature qw(state);
use Object::Pad;
use JSON::MaybeUTF8 qw(decode_json_text);
use Scalar::Util qw(blessed);
use Data::Compare qw(Compare);
use Log::Any qw($log);
use WebService::GrowthBook::FeatureRepository;
use WebService::GrowthBook::Feature;
use WebService::GrowthBook::FeatureResult;
use WebService::GrowthBook::InMemoryFeatureCache;
use WebService::GrowthBook::Eval qw(eval_condition);
use WebService::GrowthBook::Util qw(gbhash in_range get_query_string_override get_bucket_ranges choose_variation in_namespace adjust_args_camel_to_snake);
use WebService::GrowthBook::Experiment;
use WebService::GrowthBook::Result;

our $VERSION = '0.003';

=head1 NAME

WebService::GrowthBook - sdk of growthbook

=head1 SYNOPSIS

    use WebService::GrowthBook;
    my $instance = WebService::GrowthBook->new(client_key => 'my key');
    $instance->load_features;
    if($instance->is_on('feature_name')){
        # do something
    }
    else {
        # do something else
    }
    my $string_feature = $instance->get_feature_value('string_feature');
    my $number_feature = $instance->get_feature_value('number_feature');
    # get decoded json
    my $json_feature = $instance->get_feature_value('json_feature');

=head1 DESCRIPTION

    This module is a sdk of growthbook, it provides a simple way to use growthbook features.

=cut

# singletons

class WebService::GrowthBook {
    field $enabled :param //= 1;
    field $url :param //= 'https://cdn.growthbook.io';
    field $client_key :param //= "";
    field $features :param //= {};
    field $attributes :param :reader :writer //= {};
    field $cache_ttl :param //= 60;
    field $user :param //= {};
    field $forced_variations :param //= {};
    field $overrides :param //= {};
    field $sticky_bucket_service :param //= undef;
    field $groups :param //= {};
    field $qa_mode :param //= 0;
    field $on_experiment_viewed :param //= undef;
    field $tracking_callback :param //= undef;

    field $cache //= WebService::GrowthBook::InMemoryFeatureCache->singleton;
    field $sticky_bucket_assignment_docs //= {};
    field $tracked = {};
    field $assigned = {};
    field $subscriptions = [];

    sub BUILDARGS{
        my ($class, %args) = @_;
        adjust_args_camel_to_snake(\%args);
        return %args;
    }

    ADJUST {
        $tracking_callback //= $on_experiment_viewed;
        if($features){
            $self->set_features($features);
        }
    }
    method load_features {
        my $feature_repository = WebService::GrowthBook::FeatureRepository->new(cache => $cache);
        my $loaded_features = $feature_repository->load_features($url, $client_key, $cache_ttl);
        if($loaded_features){
            $self->set_features($loaded_features);
            return 1;
        }
        return undef;
    }
    method set_features($features_set) {
        $features = {};
        for my $feature_id (keys $features_set->%*) {
            my $feature = $features_set->{$feature_id};
            if(blessed($feature) && $feature->isa('WebService::GrowthBook::Feature')){
                $features->{$feature->id} = $feature;
            }
            else {
                $features->{$feature_id} = WebService::GrowthBook::Feature->new(id => $feature_id, default_value => $feature->{defaultValue}, rules => $feature->{rules});
            }
        }
    }

    method is_on($feature_name) {
        my $result = $self->eval_feature($feature_name);
        return undef unless defined($result);
        return $result->on;
    }

    method is_off($feature_name) {
        my $result = $self->eval_feature($feature_name);
        return undef unless defined($result);
        return $result->off;
    }

    # I don't know why it is called stack in python version SDK. In fact it is a hash/dict
    method _eval_feature($feature_name, $stack){
        $log->debug("Evaluating feature $feature_name");
        if(!exists($features->{$feature_name})){
            $log->debugf("No such feature: %s", $feature_name);
            return WebService::GrowthBook::FeatureResult->new(feature_id => $feature_name, value => undef, source => "unknownFeature");
        }

        if ($stack->{$feature_name}) {
            $log->warnf("Cyclic prerequisite detected, stack: %s", $stack);
            return WebService::GrowthBook::FeatureResult->new(id => $feature_name, value => undef, source => "cyclicPrerequisite");
        }

        $stack->{$feature_name} = 1;

        my $feature = $features->{$feature_name};
        for my $rule (@{$feature->rules}){
            $log->debugf("Evaluating feature %s, rule %s", $feature_name, $rule->to_hash());
            if ($rule->parent_conditions){
                my $prereq_res = $self->eval_prereqs($rule->parent_conditions, $stack);
                if ($prereq_res eq "gate") {
                    $log->debugf("Top-lavel prerequisite failed, return undef, feature %s", $feature_name);
                    return WebService::GrowthBook::FeatureResult->new(id => $feature_name, value => undef, source => "prerequisite");
                }
                elsif ($prereq_res eq "cyclic") {
                    return WebService::GrowthBook::FeatureResult->new(id => $feature_name, value => undef, source => "cyclicPrerequisite");
                }
                elsif ($prereq_res eq "fail") {
                    $log->debugf("Skip rule becasue of failing prerequisite, feature %s", $feature_name);
                    next;
                }
            }

            if ($rule->condition){
                if (!eval_condition($attributes, $rule->condition)){
                    $log->debugf("Skip rule because of failed condition, feature %s", $feature_name);
                    next;
                }
            }

            if ($rule->filters) {
                if ($self->_is_filtered_out($rule->filters)) {
                    $log->debugf(
                        "Skip rule because of filters/namespaces, feature %s", $feature_name
                    );
                    next;
                }
            }

            if (defined($rule->force)){
                if(!$self->_is_included_in_rollout($rule->seed || $feature_name,
                    $rule->hash_attribute,
                    $rule->fallback_attribute,
                    $rule->range,
                    $rule->coverage,
                    $rule->hash_version
                )){
                    $log->debugf(
                        "Skip rule because user not included in percentage rollout, feature %s",
                        $feature_name,
                    );
                    next;
                }
                $log->debugf("Force value from rule, feature %s", $feature_name);
                return WebService::GrowthBook::FeatureResult->new(
                    value => $rule->force,
                    source => "force",
                    rule_id => $rule->id,
                    feature_id => $feature_name,
                );
            }

            if(!defined($rule->variations)){
                $log->warnf("Skip invalid rule, feature %s", $feature_name);
                next;
            }
            my $exp = WebService::GrowthBook::Experiment->new(
                # TODO change $feature_name to $key
                key                     => $rule->key || $feature_name,
                variations              => $rule->variations,
                coverage                => $rule->coverage,
                weights                 => $rule->weights,
                hash_attribute          => $rule->hash_attribute,
                fallback_attribute      => $rule->fallback_attribute,
                namespace               => $rule->namespace,
                hash_version            => $rule->hash_version,
                meta                    => $rule->meta,
                ranges                  => $rule->ranges,
                name                    => $rule->name,
                phase                   => $rule->phase,
                seed                    => $rule->seed,
                filters                 => $rule->filters,
                # skip condition, since it will break test 246 and there is no condition in go version
                #condition               => $rule->condition,
                disable_sticky_bucketing => $rule->disable_sticky_bucketing,
                bucket_version          => $rule->bucket_version,
                min_bucket_version      => $rule->min_bucket_version,
            );
            my $result = $self->_run($exp, $feature_name);
            $self->_fire_subscriptions($exp, $result);
            if (!$result->in_experiment) {
                $log->debugf(
                    "Skip rule because user not included in experiment, feature %s", $feature_name
                );
                next;
            }
            if ($result->passthrough) {
                $log->debugf("Continue to next rule, feature %s", $feature_name);

                next;
            }

            $log->debugf("Assign value from experiment, feature %s", $feature_name);
            return WebService::GrowthBook::FeatureResult->new(
                value => $result->value,
                source => "experiment",
                experiment => $exp,
                experiment_result => $result,
                rule_id => $rule->id,
                feature_id => $feature_name,
            );
        }
        my $default_value = $feature->default_value;

        return WebService::GrowthBook::FeatureResult->new(
            feature_id => $feature_name,
            value => $default_value,
            source => "defaultValue",
            );
    }

    method _fire_subscriptions($experiment, $result) {
        my $prev = $assigned->{$experiment->key};
        if (
            !$prev
            || $prev->{result}->in_experiment != $result->in_experiment
            || $prev->{result}->variation_id != $result->variation_id
        ) {
            $assigned->{$experiment->key} = {
                experiment => $experiment,
                result => $result,
            };
            foreach my $cb (@{$subscriptions}) {
                eval {
                    $cb->($experiment, $result);
                } or do {
                    # Handle exception silently
                };
            }
        }
    }

    method _run($experiment, $feature_id = undef){
        # 1. If experiment has less than 2 variations, return immediately
        if (scalar @{$experiment->variations} < 2) {
            $log->warnf(
                "Experiment %s has less than 2 variations, skip", $experiment->key
            );
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        # 2. If growthbook is disabled, return immediately
        if (!$enabled) {
            $log->debugf(
                "Skip experiment %s because GrowthBook is disabled", $experiment->key
            );
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }
        # 2.5. If the experiment props have been overridden, merge them in
        if (exists $overrides->{$experiment->key}) {
            $experiment->update($overrides->{$experiment->{key}});
        }

        # 3. If experiment is forced via a querystring in the URL
        my $qs = get_query_string_override(
            $experiment->key, $url, scalar @{$experiment->variations}
        );
        if (defined $qs) {
            $log->debugf(
                "Force variation %d from URL querystring, experiment %s",
                $qs,
                $experiment->key,
            );
            return $self->_get_experiment_result($experiment, variation_id => $qs, feature_id => $feature_id);
        }

        # 4. If variation is forced in the context
        if (exists $forced_variations->{$experiment->key}) {
            $log->debugf(
                "Force variation %d from GrowthBook context, experiment %s",
                $forced_variations->{$experiment->key},
                $experiment->key,
            );
            return $self->_get_experiment_result(
                $experiment, variation_id => $forced_variations->{$experiment->key}, feature_id => $feature_id
            );
        }

        # 5. If experiment is a draft or not active, return immediately
        if ($experiment->status eq "draft" or not $experiment->active) {
            $log->debugf("Experiment %s is not active, skip", $experiment->key);
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        # 6. Get the user hash attribute and value
        my ($hash_attribute, $hash_value) = $self->_get_hash_value($experiment->hash_attribute, $experiment->fallback_attribute);
        if (!$hash_value) {
            $log->debugf(
                "Skip experiment %s because user's hashAttribute value is empty",
                $experiment->key,
            );
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        my $assigned = -1;

        my $found_sticky_bucket = 0;
        my $sticky_bucket_version_is_blocked = 0;
        if ($sticky_bucket_service && !$experiment->disableStickyBucketing) {
            my $sticky_bucket = $self->_get_sticky_bucket_variation(
                experiment_key       => $experiment->key,
                bucket_version       => $experiment->bucketVersion,
                min_bucket_version   => $experiment->minBucketVersion,
                meta                 => $experiment->meta,
                hash_attribute       => $experiment->hashAttribute,
                fallback_attribute   => $experiment->fallbackAttribute,
            );
            $found_sticky_bucket = $sticky_bucket->{variation} >= 0;
            $assigned = $sticky_bucket->{variation};
            $sticky_bucket_version_is_blocked = $sticky_bucket->{versionIsBlocked};
        }


        if ($found_sticky_bucket) {
            $log->debugf(
                "Found sticky bucket for experiment %s, assigning sticky variation %s",
                $experiment->key, $assigned
            );
        }

        # Some checks are not needed if we already have a sticky bucket
        else {
            if ($experiment->filters){

                # 7. Filtered out / not in namespace
                if ($self->_is_filtered_out($experiment->filters)) {
                    $log->debugf(
                        "Skip experiment %s because of filters/namespaces", $experiment->key
                    );
                    return $self->_get_experiment_result($experiment, feature_id => $feature_id);
                }
            }
            elsif ($experiment->namespace && !in_namespace($hash_value, $experiment->namespace)) {
                $log->debugf("Skip experiment %s because of namespace", $experiment->key);
                return $self->_get_experiment_result($experiment, feature_id => $feature_id);
            }

            # 7.5. If experiment has an include property
            if ($experiment->include) {
                eval {
                    unless ($experiment->include->()) {
                        $log->debugf(
                            "Skip experiment %s because include() returned false",
                            $experiment->key,
                        );
                        return $self->_get_experiment_result($experiment, feature_id => $feature_id);
                    }
                } or do {
                    $log->warnf(
                        "Skip experiment %s because include() raised an Exception",
                        $experiment->key,
                    );
                    return $self->_get_experiment_result($experiment, feature_id => $feature_id);
                };
            }

            # 8. Exclude if condition is false
            if ($experiment->condition && !eval_condition($self->attributes, $experiment->condition)) {
                $log->debugf(
                    "Skip experiment %s because user failed the condition", $experiment->key
                );
                return $self->_get_experiment_result($experiment, feature_id => $feature_id);
            }

            # 8.05 Exclude if parent conditions are not met
            if ($experiment->parent_conditions) {
                my $prereq_res = $self->eval_prereqs($experiment->parent_conditions, {});
                if ($prereq_res eq "gate" || $prereq_res eq "fail") {
                    $log->debugf(
                        "Skip experiment %s because of failing prerequisite", $experiment->key
                    );
                    return $self->_get_experiment_result($experiment, feature_id => $feature_id);
                }
                if ($prereq_res eq "cyclic") {
                    $log->debugf(
                        "Skip experiment %s because of cyclic prerequisite", $experiment->key
                    );
                    return $self->_get_experiment_result($experiment, feature_id => $feature_id);
                }
            }

            # 8.1. Make sure user is in a matching group
            if ($experiment->groups && @{$experiment->groups}) {
                my $exp_groups = $groups || {};
                my $matched = 0;
                foreach my $group (@{$experiment->groups}) {
                    if ($exp_groups->{$group}) {
                        $matched = 1;
                        last;
                    }
                }
                if (!$matched) {
                    $log->debugf(
                        "Skip experiment %s because user not in required group",
                        $experiment->key,
                    );
                    return $self->_get_experiment_result($experiment, feature_id => $feature_id);
                }
            }

        }

        # The following apply even when in a sticky bucket

        # 8.2. If experiment.url is set, see if it's valid
        if ($experiment->url) {
            unless ($self->_url_is_valid($experiment->url)) {
                $log->debugf(
                    "Skip experiment %s because current URL is not targeted",
                    $experiment->key,
                );
                return $self->_get_experiment_result($experiment, feature_id => $feature_id);
            }
        }

        # 9. Get bucket ranges and choose variation
        my $n = gbhash(
            $experiment->seed // $experiment->key, $hash_value, $experiment->hash_version // 1
        );
        if (!defined $n) {
            $log->warnf(
                "Skip experiment %s because of invalid hashVersion", $experiment->key
            );
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        if (!$found_sticky_bucket) {
            my $c = $experiment->coverage;
            my $ranges = $experiment->ranges || get_bucket_ranges(
                scalar @{$experiment->variations}, defined $c ? $c : 1, $experiment->weights
            );
            $assigned = choose_variation($n, $ranges);

        }

        # Unenroll if any prior sticky buckets are blocked by version
        if ($sticky_bucket_version_is_blocked) {
            $log->debugf(
                "Skip experiment %s because sticky bucket version is blocked",
                $experiment->key
            );
            return $self->_get_experiment_result(
                $experiment, feature_id => $feature_id, sticky_bucket_used => 1
            );
        }

        # 10. Return if not in experiment
        if ($assigned < 0) {
            $log->debugf(
                "Skip experiment %s because user is not included in the rollout",
                $experiment->key,
            );
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        # 11. If experiment is forced, return immediately
        if (defined $experiment->force) {
            $log->debugf(
                "Force variation %d in experiment %s", $experiment->force, $experiment->key
            );
            return $self->_get_experiment_result(
                $experiment, feature_id => $feature_id, variation_id => $experiment->force
            );
        }

        # 12. Exclude if in QA mode
        if ($qa_mode) {
            $log->debugf("Skip experiment %s because of QA Mode", $experiment->key);
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        # 12.5. If experiment is stopped, return immediately
        if ($experiment->status eq "stopped") {
            $log->debugf("Skip experiment %s because it is stopped", $experiment->key);
            return $self->_get_experiment_result($experiment, feature_id => $feature_id);
        }

        # 13. Build the result object
        my $result = $self->_get_experiment_result(
            $experiment,
            variation_id => $assigned,
            hash_used => 1,
            feature_id => $feature_id,
            bucket => $n,
            sticky_bucket_used => $found_sticky_bucket
        );

        # 13.5 Persist sticky bucket
        if ($sticky_bucket_service && !$experiment->disable_sticky_bucketing) {
            my %assignment;
            $assignment{$self->_get_sticky_bucket_experiment_key(
                $experiment->key,
                $experiment->bucketVersion
            )} = $result->key;
            my $data = $self->_generate_sticky_bucket_assignment_doc(
                $hash_attribute,
                $hash_value,
                \%assignment
            );
            my $doc = $data->{doc};
            if ($doc && $data->{changed}) {
                $sticky_bucket_assignment_docs //= {};
                $sticky_bucket_assignment_docs->{$data->{key}} = $doc;
                $sticky_bucket_service->save_assignments($doc);
            }
        }
        # 14. Fire the tracking callback if set
        $self->_track($experiment, $result);

        # 15. Return the result
        $log->debugf("Assigned variation %d in experiment %s", $assigned, $experiment->key);
        return $result;
    }

    method _track($experiment, $result) {

        return unless $tracking_callback;

        my $key = $result->hash_attribute
            . $result->hash_value
            . $experiment->key
            . $result->variation_id;

        unless ($tracked->{$key}) {
            eval {
                $tracking_callback->($experiment, $result);
                $tracked->{$key} = 1;
            } or do {
                # Handle exception silently
            };
        }
    }

    method _generate_sticky_bucket_assignment_doc($attribute_name, $attribute_value, $assignments){
        my $key = $attribute_name . "||" . $attribute_value;
        my $existing_assignments = $sticky_bucket_assignment_docs->{$key}{assignments} // {};

        my %new_assignments = (%$existing_assignments, %$assignments);

        my $changed = !Compare($existing_assignments, \%new_assignments);

        return {
            key => $key,
            doc => {
                attribute_name => $attribute_name,
                attribute_value => $attribute_value,
                assignments => \%new_assignments
            },
            changed => $changed
        };
    }

    method _url_is_valid($pattern) {

        return 0 unless $url;

        eval {
            my $r = qr/$pattern/;
            if ($self->{_url} =~ $r) {
                return 1;
            }

            my $path_only = $url;
            $path_only =~ s/^[^\/]*\//\//;
            $path_only =~ s/^https?:\/\///;

            if ($path_only =~ $r) {
                return 1;
            }
            return 0;
        } or do {
            return 1;
        };
    }

    method _is_filtered_out($filters) {

        foreach my $filter (@$filters) {
            my ($dummy, $hash_value) = $self->_get_hash_value($filter->{attribute} // "id");
            if ($hash_value eq "") {
                return 0;
            }

            my $n = gbhash($filter->{seed} // "", $hash_value, $filter->{hashVersion} // 2);
            if (!defined $n) {
                return 0;
            }

            my $filtered = 0;
            foreach my $range (@{$filter->{ranges}}) {
                if (in_range($n, $range)) {
                    $filtered = 1;
                    last;
                }
            }
            if (!$filtered) {
                return 1;
            }
        }
        return 0;
    }

    method _get_sticky_bucket_assignments($attr = '', $fallback = ''){
        my %merged;

        my ($dummy, $hash_value) = $self->_get_hash_value($attr);
        my $key = "$attr||$hash_value";
        if (exists $sticky_bucket_assignment_docs->{$key}) {
            %merged = %{ $sticky_bucket_assignment_docs->{$key}{assignments} };
        }

        if ($fallback) {
            ($dummy, $hash_value) = $self->_get_hash_value($fallback);
            $key = "$fallback||$hash_value";
            if (exists $self->{_sticky_bucket_assignment_docs}{$key}) {
                # Merge the fallback assignments, but don't overwrite existing ones
                for my $k (keys %{ $sticky_bucket_assignment_docs->{$key}{assignments} }) {
                    $merged{$k} //= $sticky_bucket_assignment_docs->{$key}{assignments}{$k};
                }
            }
        }

        return \%merged;
    }

    method _get_sticky_bucket_variation($experiment_key, $bucket_version = 0, $min_bucket_version = 0, $meta = {}, $hash_attribute = undef, $fallback_attribute = undef){
        my $id = $self->_get_sticky_bucket_experiment_key($experiment_key, $bucket_version);


        my $assignments = $self->_get_sticky_bucket_assignments($hash_attribute, $fallback_attribute);
        if ($self->_is_blocked($assignments, $experiment_key, $min_bucket_version)) {
            return {
                variation => -1,
                versionIsBlocked => 1
            };
        }

        my $variation_key = $assignments->{$id};
        if (!$variation_key) {
            return {
                variation => -1
            };
        }

        # Find the key in meta
        my $variation = -1;
        for (my $i = 0; $i < @$meta; $i++) {
            if ($meta->[$i]->{key} eq $variation_key) {
                $variation = $i;
                last;
            }
        }

        if ($variation < 0) {
            return {
                variation => -1
            };
        }

        return { variation => $variation };
    }

    method _is_blocked($assignments, $experiment_key, $min_bucket_version = 0){
        if ($min_bucket_version > 0) {
            for my $i (0 .. $min_bucket_version - 1) {
                my $blocked_key = $self->_get_sticky_bucket_experiment_key($experiment_key, $i);
                if (exists $assignments->{$blocked_key}) {
                    return 1;
                }
            }
        }
        return 0;
    }

    method _get_sticky_bucket_experiment_key($experiment_key, $bucket_version = 0){
        return $experiment_key . "__" . $bucket_version;
    }

    method _get_experiment_result($experiment, %args){
        my $variation_id = $args{variation_id} // -1;
        my $hash_used = $args{hash_used} // 0;
        my $feature_id = $args{feature_id};
        my $bucket = $args{bucket};
        my $sticky_bucket_used = $args{sticky_bucket_used} // 0;
        my $in_experiment = 1;
        if ($variation_id < 0 || $variation_id > @{$experiment->variations} - 1) {
            $variation_id = 0;
            $in_experiment = 0;
        }

        my $meta;
        if ($experiment->meta) {
            $meta = $experiment->meta->[$variation_id];
        }

        my ($hash_attribute, $hash_value) = $self->_get_orig_hash_value($experiment->hash_attribute, $experiment->fallback_attribute);
        return WebService::GrowthBook::Result->new(
            feature_id         => $feature_id,
            in_experiment      => $in_experiment,
            variation_id       => $variation_id,
            value              => $experiment->variations->[$variation_id],
            hash_used          => $hash_used,
            hash_attribute     => $hash_attribute,
            hash_value         => $hash_value,
            meta               => $meta,
            bucket             => $bucket,
            sticky_bucket_used => $sticky_bucket_used
        );
    }

    method _is_included_in_rollout($seed, $hash_attribute, $fallback_attribute, $range, $coverage, $hash_version){
        if (!defined($coverage) && !defined($range)){
            return 1;
        }
        my $hash_value;
        (undef, $hash_value) = $self->_get_hash_value($hash_attribute, $fallback_attribute);
        if($hash_value eq "") {

            return 0;
        }

        my $n = gbhash($seed, $hash_value, $hash_version || 1);
        if (!defined($n)){

            return 0;
        }

        if($range){

            return in_range($n, $range);
        }
        elsif($coverage){
            return $n < $coverage;
        }

        return 1;
    }

    method _get_hash_value($attr, $fallback_attr = undef){
        my $val;
        ($attr, $val) = $self->_get_orig_hash_value($attr, $fallback_attr);
        return ($attr, "$val");
    }

    method _get_orig_hash_value($attr, $fallback_attr){
        $attr ||= "id";
        my $val = "";

        if (exists $attributes->{$attr}) {
            $val = $attributes->{$attr} || "";
        } elsif (exists $user->{$attr}) {
            $val = $user->{$attr} || "";
        }

        # If no match, try fallback
        if ((!$val || $val eq "") && $fallback_attr && $self->{sticky_bucket_service}) {
            if (exists $attributes->{$fallback_attr}) {
                $val = $attributes->{$fallback_attr} || "";
            } elsif (exists $user->{$fallback_attr}) {
                $val = $user->{$fallback_attr} || "";
            }

            if (!$val || $val ne "") {
                $attr = $fallback_attr;
            }
        }

        return ($attr, $val);
    }

    method eval_prereqs($parent_conditions, $stack){
        foreach my $parent_condition (@$parent_conditions) {
            my $parent_res = $self->_eval_feature($parent_condition->{id}, $stack);

            if ($parent_res->{source} eq "cyclicPrerequisite") {
                return "cyclic";
            }

            if (!eval_condition({ value => $parent_res->{value} }, $parent_condition->{condition})) {
                if ($parent_condition->{gate}) {
                    return "gate";
                }
                return "fail";
            }
        }
        return "pass";
    }
    method eval_feature($feature_name){
        return $self->_eval_feature($feature_name, {});
    }

    method get_feature_value($feature_name, $fallback = undef){
        my $result = $self->eval_feature($feature_name);
        return $fallback unless defined($result->value);
        return $result->value;
    }

    method run($experiment){
        my $result = $self->_run($experiment);
        $self->_fire_subscriptions($experiment, $result);
        return $result;
    }
}

=head1 METHODS

=head2 load_features

load features from growthbook API

    $instance->load_features;

=head2 is_on

check if a feature is on

    $instance->is_on('feature_name');

Please note it will return undef if the feature does not exist.

=head2 is_off

check if a feature is off

    $instance->is_off('feature_name');

Please note it will return undef if the feature does not exist.

=head2 get_feature_value

get the value of a feature

    $instance->get_feature_value('feature_name');

Please note it will return undef if the feature does not exist.

=head2 set_features

set features

    $instance->set_features($features);

=head2 eval_feature

evaluate a feature to get the value

    $instance->eval_feature('feature_name');

=head2 set_attributes

set attributes (can be set when creating gb object) and evaluate features

    $instance->set_attributes({attr1 => 'value1', attr2 => 'value2'});
    $instance->eval_feature('feature_name');

=cut


1;


=head1 SEE ALSO

=over 4

=item * L<https://docs.growthbook.io/>

=item * L<PYTHON VERSION|https://github.com/growthbook/growthbook-python>

=back

