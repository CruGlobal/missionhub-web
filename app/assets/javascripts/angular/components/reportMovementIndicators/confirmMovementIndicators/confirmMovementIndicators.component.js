import { t } from 'i18next';
import _ from 'lodash';

import './confirmMovementIndicators.scss';
import warningIcon from '../../../../../images/icons/icon-warning-2.svg';
import checkIcon from '../../../../../images/icons/icon-check-stylized.svg';

import template from './confirmMovementIndicators.html';

angular.module('missionhubApp').component('reportMovementIndicatorsConfirm', {
    controller: reportMovementIndicatorsConfirmController,
    bindings: {
        orgId: '<',
        next: '&',
        previous: '&',
    },
    template,
});

function reportMovementIndicatorsConfirmController(httpProxy, $uibModal) {
    this.fieldMap = {
        interactions: {
            spiritualConversations: {
                label: t(
                    'movementIndicators:interactions.spiritualConversations.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.spiritualConversations.tooltip',
                ),
                apiField: 'spiritual_conversation_interactions',
            },
            personalEvangelism: {
                label: t(
                    'movementIndicators:interactions.personalEvangelism.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.personalEvangelism.tooltip',
                ),
                apiField: 'gospel_presentation_interactions',
            },
            personalEvangelismDecisions: {
                label: t(
                    'movementIndicators:interactions.personalEvangelismDecisions.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.personalEvangelismDecisions.tooltip',
                ),
                apiField: 'prayed_to_receive_christ_interactions',
            },
            holySpiritPresentations: {
                label: t(
                    'movementIndicators:interactions.holySpiritPresentations.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.holySpiritPresentations.tooltip',
                ),
                apiField: 'holy_spirit_presentation_interactions',
            },
            groupEvangelism: {
                label: t(
                    'movementIndicators:interactions.groupEvangelism.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.groupEvangelism.tooltip',
                ),
                apiField: 'group_evangelism',
            },
            groupEvangelismDecisions: {
                label: t(
                    'movementIndicators:interactions.groupEvangelismDecisions.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.groupEvangelismDecisions.tooltip',
                ),
                apiField: 'group_evangelism_decision',
            },
            mediaExposures: {
                label: t(
                    'movementIndicators:interactions.mediaExposures.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.mediaExposures.tooltip',
                ),
                apiField: 'media_exposure',
            },
            mediaExposureDecisions: {
                label: t(
                    'movementIndicators:interactions.mediaExposureDecisions.label',
                ),
                tooltip: t(
                    'movementIndicators:interactions.mediaExposureDecisions.tooltip',
                ),
                apiField: 'media_exposure_decisions',
            },
        },
        students: {
            involved: {
                label: t('movementIndicators:students.involved.label'),
                tooltip: t('movementIndicators:students.involved.tooltip'),
                apiField: 'students_involved',
            },
            engaged: {
                label: t('movementIndicators:students.engaged.label'),
                tooltip: t('movementIndicators:students.engaged.tooltip'),
                apiField: 'students_engaged',
            },
            leaders: {
                label: t('movementIndicators:students.leaders.label'),
                tooltip: t('movementIndicators:students.leaders.tooltip'),
                apiField: 'student_leaders',
            },
        },
        faculty: {
            involved: {
                label: t('movementIndicators:faculty.involved.label'),
                tooltip: t('movementIndicators:faculty.involved.tooltip'),
                apiField: 'faculty_involved',
            },
            engaged: {
                label: t('movementIndicators:faculty.engaged.label'),
                tooltip: t('movementIndicators:faculty.engaged.tooltip'),
                apiField: 'faculty_engaged',
            },
            leaders: {
                label: t('movementIndicators:faculty.leaders.label'),
                tooltip: t('movementIndicators:faculty.leaders.tooltip'),
                apiField: 'faculty_leaders',
            },
        },
    };

    this.$onInit = () => {
        loadMovementIndicators(this.orgId);
    };

    const loadMovementIndicators = orgId => {
        this.loadingMovementIndicators = true;
        return httpProxy
            .get(
                `/movement_indicators/${orgId}`,
                {},
                {
                    errorMessage: t(
                        'movementIndicators:confirmIndicators.errorLoadingIndicators',
                    ),
                },
            )
            .then(({ data, meta }) => {
                this.startDate = meta.start_date;
                this.endDate = meta.end_date;
                this.submittedInLastWeek = data.submitted_in_last_week;
                this.fieldMap = _.mapValues(this.fieldMap, indicatorGroup =>
                    _.mapValues(indicatorGroup, indicator => ({
                        ...indicator,
                        value: data[indicator.apiField],
                    })),
                );
                delete this.loadingMovementIndicators;
            });
    };

    this.submit = async () => {
        const data = {
            data: {
                type: 'movement_indicator_submission',
                attributes: Object.values(this.fieldMap).reduce(
                    (acc, indicatorGroup) => ({
                        ...acc,
                        ...Object.values(indicatorGroup).reduce(
                            (acc, indicator) => ({
                                ...acc,
                                [indicator.apiField]: indicator.value,
                            }),
                            {},
                        ),
                    }),
                    {},
                ),
            },
        };

        await $uibModal.open({
            component: 'iconModal',
            resolve: {
                icon: () => warningIcon,
                reducedPadding: () => true,
                paragraphs: () => [
                    t('movementIndicators:confirmModal.description'),
                ],
                dismissLabel: () => t('goBack'),
                closeLabel: () => t('submit'),
            },
        }).result;
        try {
            await httpProxy.put(`/movement_indicators/${this.orgId}`, data, {
                errorMessage: t(
                    'movementIndicators:confirmIndicators.errorSavingIndicators',
                ),
                ignoreFilter: () => false, // Needed to get the httpProxy to return a promise on failure instead of waiting indefinitely for toast to be clicked to retry the failed request
            });
            await $uibModal.open({
                component: 'iconModal',
                resolve: {
                    icon: () => checkIcon,
                    title: () => t('movementIndicators:successModal.title'),
                    closeLabel: () => t('ok'),
                },
            }).result;
            this.next();
        } catch (e) {
            await $uibModal.open({
                component: 'iconModal',
                resolve: {
                    icon: () => warningIcon,
                    title: () => t('movementIndicators:errorModal.title'),
                    paragraphs: () => [
                        t('movementIndicators:errorModal.description'),
                    ],
                    closeLabel: () => t('ok'),
                },
            }).result;
        }
    };
}
