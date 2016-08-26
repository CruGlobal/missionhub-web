//= require vex-js/dist/vex.combined.min

$(document).ready(function () {
    // Find and return the reserved organization that matches the provided organization name,
    // or undefined if no matches could be found
    function findOrganizationMatches (organization) {
        var reservedOrganizations = [
            { name: 'Cru', aliases: ['cru', 'campus crusade', 'campus crusade for christ', 'ccc'] },
            { name: 'Bridges', aliases: ['bridges'] },
            { name: 'Power to Change', aliases: ['power to change', 'power 2 change', 'power2change', 'p2c'] },
            { name: 'Athletes in Action', aliases: ['athletes in action', 'aia'] }
        ];

        var basicName = organization.toLowerCase().split(' at ')[0].trim();

        // Return the first reserved organization with an alias that matches the checked organization name
        var matchedOrganizations = reservedOrganizations.filter(function (organization) {
            return organization.aliases.indexOf(basicName) !== -1;
        });

        // Will be undefined if no organizations matched
        return matchedOrganizations[0];
    }

    $('#new_request_access').on('submit', function (e) {
        var $form = $(this);
        var matchedOrganization = findOrganizationMatches($form.find('#request_access_org_name').val());
        if (matchedOrganization) {
            var message = 'You requested a new ministry called ' + matchedOrganization.name + '. Many of ' +
                matchedOrganization.name + '’s ministries already exist in MissionHub. Ask one of your leaders at ' +
                matchedOrganization.name + ' to send you an invite to MissionHub.';
            var dialog = vex.open({
                unsafeContent:
                  '<p class="message">' + message + '</p>' +
                  '<input type="button" value="OK" class="btn">',
                className: 'vex-theme-default existing-organization',
                showCloseButton: false,
                afterOpen: function () {
                    $(this.contentEl).find(':button').click(function () {
                        dialog.close();
                    });
                }
            });
            e.preventDefault();
        } else if ($form.data('submitted') === true) {
            // Previously submitted - don't submit again
            e.preventDefault();
        } else {
            // Mark it so that the next submit can be ignored
            $form.data('submitted', true);
            $form.find('[type=submit]').val('Submitting...');
        }
    });
});
