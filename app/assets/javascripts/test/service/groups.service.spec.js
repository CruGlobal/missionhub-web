(function () {
    'use strict';

    // Constants
    var groupsService, $q, $rootScope, httpProxy, JsonApiDataStore;

    // Add better asynchronous support to a test function
    // The test function must return a promise
    // The promise will automatically be bound to "done" and the $rootScope will be automatically digested
    function asynchronous (fn) {
        return function (done) {
            var returnValue = fn.call(this, done);
            returnValue.then(function () {
                done();
            }).catch(function (err) {
                done.fail(err);
            });
            $rootScope.$apply();
            return returnValue;
        };
    }

    describe('groupsService', function () {
        beforeEach(angular.mock.module('missionhubApp'));

        beforeEach(inject(function (_groupsService_, _$q_, _$rootScope_, _httpProxy_, _JsonApiDataStore_) {
            var _this = this;

            groupsService = _groupsService_;
            $q = _$q_;
            $rootScope = _$rootScope_;
            httpProxy = _httpProxy_;
            JsonApiDataStore = _JsonApiDataStore_;

            this.organizationId = 1;
            this.groupAttributes = {
                name: 'Test group',
                location: 'Somwhere great',
                meets: 'weekly',
                meeting_day: 'Thursday',
                start_time: 64800,
                end_time: 69300
            };

            // Can be changed in individual tests
            this.httpResponse = $q.resolve({
                data: this.groupAttributes
            });
            spyOn(httpProxy, 'callHttp').and.callFake(function () {
                return _this.httpResponse;
            });
        }));

        describe('createGroup', function () {
            it('should make a network request', function () {
                groupsService.createGroup(angular.extend({
                    _type: 'group'
                }, this.groupAttributes), this.organizationId);

                expect(httpProxy.callHttp).toHaveBeenCalledWith(
                    'POST',
                    jasmine.any(String),
                    null,
                    {
                        data: {
                            attributes: this.groupAttributes,
                            relationships: {
                                organization: {
                                    data: { id: this.organizationId, type: 'organization' }
                                }
                            },
                            type: 'group'
                        }
                    },
                    undefined
                );
            });

            it('should return a promise that resolves to the new group', asynchronous(function () {
                var _this = this;
                return groupsService.createGroup(this.groupAttributes, this.organizationId).then(function (group) {
                    expect(group).toEqual(jasmine.objectContaining(_this.groupAttributes));
                });
            }));

            it('should add the group to the organization', asynchronous(function () {
                var org = JsonApiDataStore.store.sync({
                    data: {
                        type: 'organization',
                        id: this.organizationId,
                        relationships: {
                            groups: {
                                data: []
                            }
                        }
                    }
                });
                return groupsService.createGroup(this.groupAttributes, this.organizationId).then(function (group) {
                    expect(org.groups).toEqual(jasmine.arrayContaining([group]));
                });
            }));
        });
    });
})();
