(function () {
    'use strict';

    angular
        .module('missionhubApp')
        .factory('assignedSelectService', assignedSelectService);

    function assignedSelectService (httpProxy, modelsService, loggedInPerson, permissionService) {
        return {
            // Search for people in a particular organization that match the query
            searchPeople: function (query, organizationId, httpConfig) {
                return httpProxy.get(modelsService.getModelMetadata('person').url.search, {
                    q: query,
                    organization_ids: organizationId,
                    'filters[permission_ids]': permissionService.adminAndUserIds.join(',')
                }, httpConfig).then(httpProxy.extractModels);
            },

            // Determine whether a person is the currently logged-in person
            isMe: function (person) {
                return loggedInPerson.person === person;
            }
        };
    }
})();