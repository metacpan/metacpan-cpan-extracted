{
  en => {
    attributes => {
      username => "User Name",
    },
    valiant => {
      errors => {
        models => {
          'example/schema/result/profile' => {
            attributes => {
              registered => {
                bad_state => "Can't register is the state of {{state}}",
                'format/bad_state' => "{{message}}",
              },
            },
          },
        },
      },
      attributes => {
        'example/model/schema/person' => {
          person_roles => "Roles",
        },
      }
    }
  },
};

