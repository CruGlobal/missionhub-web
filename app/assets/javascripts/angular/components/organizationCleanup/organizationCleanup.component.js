import template from './organizationCleanup.html';
import './organizationCleanup.scss';

angular.module('missionhubApp').component('organizationCleanup', {
    bindings: {
        orgId: '<',
    },
    template: template,
    controller: organizationCleanupController,
});

function organizationCleanupController(httpProxy) {
    this.archiveBeforeDate = new Date();
    this.archiveInactivityDate = new Date();
    this.dateOptions = {
        formatYear: 'yy',
        maxDate: new Date(2020, 5, 22),
        minDate: new Date(),
        startingDay: 1,
    };

    const archiveContacts = async (archiveBy, dateBy) => {
        return await httpProxy.post(
            '/organizations/archives',
            {
                type: 'bulk_archive_contacts',
                id: this.orgId,
                'attributes[organization_id]': this.orgId,
                'attributes[before_date]': dateBy.string(),
                'attributes[archive_by]': archiveBy,
                'attributes[archived]': true,
            },
            {
                errorMessage: 'error.messages.organization.cleanup',
            },
        );
    };

    this.archiveInactive = async dateBy => {
        const { data } = archiveContacts('leaders_last_sign_in_at', dateBy);
    };

    this.archiveBefore = async dateBy => {
        const { data } = archiveContacts('persons_inactive_since', dateBy);
    };
}
