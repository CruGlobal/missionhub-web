(function () {
    'use strict';

    angular
        .module('missionhubApp')
        .component('reportPeriod', {
            controller: reportPeriodController,
            templateUrl: '/assets/angular/components/reportPeriod/reportPeriod.html'
        });

    function reportPeriodController (periodService) {
        var vm = this;
        vm.periods = [
            {label: 'dashboard.report_periods.one_week', period: 'P1W'},
            {label: 'dashboard.report_periods.one_month', period: 'P1M'},
            {label: 'dashboard.report_periods.three_months', period: 'P3M'},
            {label: 'dashboard.report_periods.six_months', period: 'P6M'},
            {label: 'dashboard.report_periods.one_year', period: 'P1Y'}
        ];

        vm.getPeriod = periodService.getPeriod;
        vm.setPeriod = periodService.setPeriod;
    }
})();
