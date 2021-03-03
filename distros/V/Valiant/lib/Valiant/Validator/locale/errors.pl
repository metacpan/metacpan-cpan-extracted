{
  en => {
    attributes => {
      retirement_date => 'Retires On',
    },
    errors => {
      messages => {
        # numericality
        less_than_or_equal_to_err => 'must be less than or equal to {{count}}',
        is_number_err => "is not a number",
        is_integer_err => "must be an integer",
        greater_than_err => "must be greater than {{count}}",
        greater_than_or_equal_to_err => "must be greater than or equal to {{count}}",
        equal_to_err => "must be equal to {{count}}",
        less_than_err => "must be less than {{count}}",
        other_than_err => "must be other than {{count}}",
        odd_err => "must be odd",
        even_err => "must be even",
        divisible_by_err => "is not evenly divisible by {{count}}",
        decimals_err => "must have exactly {{count}} decimal places",
        positive_integer_err => 'must be a positive integer',
        negative_integer_err => 'must be a negative integer',
        positive_err => 'must be a positive number',
        negative_err => 'must be a negative number',
        pg_serial => 'is not in acceptable value range',
        pg_bigserial => 'is not in acceptable value range',
        # length
        too_short => {
          one => 'is too short (minimum is 1 character)',
          other => 'is too short (minimum is {{count}} characters)',
        },
        too_long => {
          one => 'is too long (maximum is 1 character)',
          other => 'is too long (maximum is {{count}} characters)',
        },
        wrong_length => {
          one => "is the wrong length (should be 1 character)",
          other => "is the wrong length (should be {{count}} characters)",
        },
        # presence
        is_blank => "can't be blank",
        # absence
        is_present => 'must be blank',
        # inclusion
        inclusion => 'is not in the list',
        # exclusion
        exclusion => 'is reserved',
        # format
        invalid_format_match => 'does not match the required pattern',
        invalid_format_without => 'contains invalid characters',
        not_alpha => 'must contain only alphabetic characters',
        not_words => 'must be letters and spaces only',
        not_alpha_numeric => 'must contain only alphabetic and number characters',
        not_email => 'is not an email address',
        not_zip => 'is not a zip code',
        not_zip5 => 'is not a zip code',
        not_zip9 => 'is not a zip code',
        # confirmation
        confirmation => "doesn't match '{{attribute}}'",
        #only_of
        only_of => {
          one => 'please choose only {{count}} field',
          other => 'please choose only {{count}} fields'
        },
        #check
        check => 'is invalid',
        #boolean
        is_not_true => 'must be a true value',
        is_not_false => 'must be a false value',
        #unique
        is_not_unique => 'chosen is not unique',
        #date
        above_max => "chosen date can't be later than {{max}}",
        below_min => "chosen date can't be earlier than {{min}}",
        invalid_date => "doesn't look like a date",
        #object
        not_blessed => 'is not an object',
        type_constraint_violation => 'violates type constraint "{{display_name}}"',
        wrong_inheritance => 'does not inherit from "{{parent}}"',
        not_role => 'does not provide the role "{{role}}"',
        #array
        max_length_err => 'has too many items (maximum is {{max}})',
        min_length_err => 'has too few rows (minimum is {{min}})',
        not_array_err => 'is not an array',
      },
    }
  },
};
