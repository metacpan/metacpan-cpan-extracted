#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Main module
use_ok('WWW::MetaForge');

# Shared cache
use_ok('WWW::MetaForge::Cache');

# GameMapData
use_ok('WWW::MetaForge::GameMapData');
use_ok('WWW::MetaForge::GameMapData::Request');
use_ok('WWW::MetaForge::GameMapData::Result::MapMarker');

# ArcRaiders
use_ok('WWW::MetaForge::ArcRaiders');
use_ok('WWW::MetaForge::ArcRaiders::Request');
use_ok('WWW::MetaForge::ArcRaiders::Result::Item');
use_ok('WWW::MetaForge::ArcRaiders::Result::Arc');
use_ok('WWW::MetaForge::ArcRaiders::Result::Quest');
use_ok('WWW::MetaForge::ArcRaiders::Result::Trader');
use_ok('WWW::MetaForge::ArcRaiders::Result::EventTimer');
use_ok('WWW::MetaForge::ArcRaiders::Result::MapMarker');

# CLI
use_ok('WWW::MetaForge::ArcRaiders::CLI');

done_testing;
