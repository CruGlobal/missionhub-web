import template from './assignedPeopleSelect.html';
import './assignedPeopleSelect.scss';

angular.module('missionhubApp').component('assignedPeopleSelect', {
    bindings: {
        assigned: '=',
        ruleCode: '<',
        organizationId: '<',
        disabled: '<',
        actionAfterSelect: '&',
    },
    controller: assignedPeopleSelectController,
    template: template,
});

function assignedPeopleSelectController(
    $scope,
    assignedPeopleSelectService,
    RequestDeduper,
) {
    this.people = [];
    this.isMe = assignedPeopleSelectService.isMe;
    this.$onInit = () => {
        const requestDeduper = new RequestDeduper();
        // Refresh the person list whenever the search term changes
        $scope.$watch('$select.search', search => {
            if (search === '') {
                // Ignore empty searches
                this.people = [];
                return;
            }

            assignedPeopleSelectService
                .searchPeople(search, this.organizationId, requestDeduper)
                .then(people => {
                    this.people = people;
                });
        });

        $scope.$watch('$ctrl.assigned', (o, n) => {
            if (this.actionAfterSelect && o !== n) {
                this.actionAfterSelect();
            }
        });
    };
}
