(function () {
    'use strict';

    angular
        .module('missionhubApp')
        .component('editGroup', {
            controller: editGroupController,
            bindings: {
                resolve: '<',
                close: '&',
                dismiss: '&'
            },
            templateUrl: '/assets/angular/components/editGroup/editGroup.html'
        });

    function editGroupController (groupsService, editGroupService, _) {
        var vm = this;

        vm.title = 'groups.new.new_group';
        vm.saving = false;
        vm.meetingFrequencyOptions = ['weekly', 'monthly', 'sporadically'];
        vm.dayOptions = _.range(1, 32);

        vm.valid = valid;
        vm.save = save;
        vm.cancel = cancel;

        vm.$onInit = activate;

        function activate () {
            vm.group = vm.resolve.group || createBlankGroup();
        }

        function valid () {
            return editGroupService.isGroupValid(vm.group);
        }

        function createBlankGroup () {
            vm.group = editGroupService.getGroupTemplate();
        }

        function save () {
            vm.saving = true;
            editGroupService.saveGroup(vm.group, vm.resolve.organizationId)
                .then(function (newGroup) {
                    vm.close({ $value: newGroup });
                })
                .catch(function () {
                    vm.saving = false;
                });
        }

        function cancel () {
            vm.dismiss();
        }
    }
})();