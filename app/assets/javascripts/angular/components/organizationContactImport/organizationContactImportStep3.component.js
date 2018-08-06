import template from './organizationContactImportStep3.html';
import * as Papa from 'papaparse';
import _ from 'lodash';
import uuidv1 from 'uuid';

angular.module('missionhubApp').component('organizationContactImportStep3', {
    require: {
        organizationOverview: '^',
    },
    bindings: {
        next: '&',
        previous: '&',
        selectedFile: '<',
        selectedSurvey: '<',
        columnMap: '<',
    },
    template: template,
    controller: organizationContactImportStep3Controller,
});

function organizationContactImportStep3Controller(
    $scope,
    surveyService,
    labelsService,
) {
    this.disableButtons = true;

    this.$onInit = () => {
        //parse csv
        Papa.parse(this.selectedFile, {
            complete: results => {
                if (results.errors.length) {
                    console.log('Parse errors:', results.errors);
                } else {
                    this.csvData = results.data;
                    this.disableButtons = false;
                    $scope.$digest();
                }
            },
        });
    };

    this.addLabel = labelName => {
        let label = labelsService.getLabelTemplate(
            this.selectedSurvey.organization_id,
        );
        label.name = labelName;

        labelsService.saveLabel(label).then(newLabel => {
            this.newLabelName = '';
        });
    };

    this.getLabels = () => {
        return _.keys(
            _.pickBy(this.contactLabels, value => {
                return value;
            }),
        );
    };

    this.import = () => {
        let postData = {
            included: [],
            data: {
                type: 'bulk_create_job',
                attributes: {
                    bulk_data: [],
                },
            },
        };

        _.forEach(this.csvData, record => {
            let answerIds = [],
                labelIds = [];

            //map answers
            _.forEach(this.columnMap, (question, questionIndex) => {
                const answerId = uuidv1();

                postData.included.push({
                    type: 'answer',
                    id: answerId,
                    attributes: {
                        question_id: Number(question.id),
                        value: record[questionIndex],
                    },
                });

                answerIds.push(answerId);
            });

            //map organization labels
            _.forEach(this.getLabels(), labelId => {
                const labelUUID = uuidv1();

                postData.included.push({
                    type: 'organizational_label',
                    id: labelUUID,
                    attributes: {
                        label_id: Number(labelId),
                        organization_id: this.selectedSurvey.organization_id,
                    },
                });

                labelIds.push(labelUUID);
            });

            //map answer sheets
            let answerSheet = {
                type: 'answer_sheet',
                relationships: {
                    survey: {
                        data: {
                            type: 'survey',
                            id: this.selectedSurvey.id,
                        },
                    },
                },
                answers: {
                    data: [],
                },
                organizational_labels: {
                    data: [],
                },
            };

            _.forEach(answerIds, answerId => {
                answerSheet.answers.data.push({
                    type: 'answer',
                    id: answerId,
                });
            });

            _.forEach(labelIds, labelId => {
                answerSheet.organizational_labels.data.push({
                    type: 'organizational_label',
                    id: labelId,
                });
            });

            postData.data.attributes.bulk_data.push(answerSheet);
        });

        this.disableButtons = true;
        surveyService.importContacts(postData).then(
            () => {
                this.next();
            },
            () => {
                this.disableButtons = false;
            },
        );
    };
}