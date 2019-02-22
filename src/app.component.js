import template from './app.html';
import './components/navigation/navHeader.component';
import './app.scss';

angular.module('missionhubApp').component('app', {
    controller: appController,
    template: template,
    bindings: {
        hideHeader: '<',
        hideFooter: '<',
        hideMenuLinks: '<',
    },
});

function appController(periodService, $rootScope, state, analyticsService) {
    let deregisterEditOrganizationsEvent;
    let deregisterStateChangedEvent;

    this.editOrganizations = false;
    this.getPeriod = periodService.getPeriod;
    this.currentOrganization = state.currentOrganization;

    this.$onInit = () => {
        this.year = new Date();

        deregisterStateChangedEvent = $rootScope.$on(
            'state:changed',
            (event, { loggedIn, currentOrganization }) => {
                this.currentOrganization = currentOrganization;

                if (loggedIn) analyticsService.setupAuthenitcatedAnalyticData();
                else analyticsService.clearAuthenticatedData();
            },
        );

        deregisterEditOrganizationsEvent = $rootScope.$on(
            'editOrganizations',
            (event, value) => {
                this.editOrganizations = value;
            },
        );
    };

    this.$onDestroy = () => {
        deregisterEditOrganizationsEvent();
        deregisterStateChangedEvent();
    };
}
