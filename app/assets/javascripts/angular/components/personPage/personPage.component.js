(function () {
    'use strict';

    angular
        .module('missionhubApp')
        .component('personPage', {
            controller: personPageController,
            templateUrl: /* @ngInject */ function (templateUrl) {
                return templateUrl('personPage');
            },
            bindings: {
                person: '<',
                organizationId: '<'
            }
        });

    function personPageController ($scope, $state, $filter, personService, personTabs,
                                   personPageService, _) {
        var vm = this;
        $scope.$watchCollection('$ctrl.person.email_addresses', function () {
            vm.primaryEmail = _.find(vm.person.email_addresses, { primary: true });
        });
        $scope.$watchCollection('$ctrl.person.phone_numbers', function () {
            vm.primaryPhone = _.find(vm.person.phone_numbers, { primary: true });
        });
        vm.personTabs = personTabs;
        vm.orgLabels = [];

        vm.uploadAvatar = uploadAvatar;
        vm.deleteAvatar = deleteAvatar;
        vm.updateLabels = updateLabels;
        vm.dismiss = dismiss;
        vm.updateGroupMemberships = updateGroupMemberships;
        vm.$onInit = activate;

        function activate () {
            vm.orgPermission = personService.getOrgPermission(vm.person, vm.organizationId);
            vm.assignedTo = personService.getAssignedTo(vm.person, vm.organizationId);
            $scope.$watch('$ctrl.person.picture', function (pictureUrl) {
                vm.avatarUrl = pictureUrl || $filter('assetPath')('no_image.png');
                vm.isFacebookAvatar = personPageService.isFacebookAvatar(vm.avatarUrl);
                if (vm.isFacebookAvatar) {
                    vm.avatarUrl += '?width=120&height=120';
                }
            });

            updateLabels();
            updateGroupMemberships();
        }

        function uploadAvatar (file) {
            if (file) {
                personPageService.uploadAvatar(vm.person, file);
            }
        }

        function deleteAvatar () {
            personPageService.deleteAvatar(vm.person);
        }

        function updateLabels () {
            vm.orgLabels = personService.getOrgLabels(vm.person, vm.organizationId);
        }

        // Dismiss this page
        function dismiss () {
            $state.go('^.^');
        }

        function updateGroupMemberships () {
            vm.groupMemberships = personService.getGroupMemberships(vm.person, vm.organizationId);
        }
    }
})();
