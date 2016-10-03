(function () {
    'use strict';

    angular
        .module('missionhubApp')
        .component('organizationOverview', {
            controller: organizationOverviewController,
            bindings: {
                org: '<',
                loadDetails: '<?'
            },
            templateUrl: '/assets/angular/components/organizationOverview/organizationOverview.html'
        });

    function organizationOverviewController (JsonApiDataStore,
                                             ministryViewTabs, ministryViewFirstTab, organizationOverviewService, _) {
        var vm = this;

        _.defaults(vm, {
            loadDetails: true
        });

        vm.tabNames = ministryViewTabs;
        vm.firstTab = ministryViewFirstTab;
        vm.$onInit = activate;

        function activate () {
            if (!vm.loadDetails) {
                // Abort before loading org details
                return;
            }

            organizationOverviewService.loadOrgRelations(vm.org).then(function () {
                // Find all of the groups related to the org
                vm.groups = vm.org.groups;

                // Find all of the surveys related to the org
                vm.surveys = vm.org.surveys;
            });

            organizationOverviewService.loadOrgSuborgs(vm.org).then(function () {
                // Find all of the organizations with org as its parent
                vm.suborgs = _.filter(JsonApiDataStore.store.findAll('organization'), {
                    ancestry: vm.org.ancestry + '/' + vm.org.id
                });
            });

            organizationOverviewService.loadOrgPeople(vm.org).then(function () {
                // Find all of the people in the org
                vm.contacts = JsonApiDataStore.store.findAll('person').filter(function (person) {
                    // Include the person if they are part of this organization
                    return _.filter(person.organizational_permissions, {
                        organization_id: vm.org.id
                    }).length > 0;
                });

                // Find all of the admins in the org
                vm.admins = vm.contacts.filter(function (person) {
                    // Include the person if they are an admin (permission_id = 1) or user (permission_id = 4)
                    // of this organization
                    // Start with the user's organizational permissions, then restrict that list to permissions for
                    // this organization, and determine whether any of those permissions have a permission_id of
                    // either 1 or 4
                    return !_.chain(person.organizational_permissions)
                        .filter({ organization_id: vm.org.id })
                        .map('permission_id')
                        .intersection([1, 4])
                        .isEmpty()
                        .value();
                });
            });
        }
    }
})();
