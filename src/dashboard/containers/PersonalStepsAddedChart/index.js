import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from 'react-apollo-hooks';
import gql from 'graphql-tag';
import styled from '@emotion/styled';

import BarChart from '../../components/BarChart';
import AppContext from '../../appContext';

const GET_STAGES_REPORT = gql`
    query organizationPathwayStagesReport(
        $period: String!
        $organizationId: ID!
    ) {
        organizationPathwayStagesReport(
            period: $period
            organizationId: $organizationId
        ) {
            memberCount
            pathwayStage {
                name
            }
            stepsAddedCount
        }
    }
`;

const Wrapper = styled.div`
    height: 400px;
`;

const PersonalStepsAdded = () => {
    const { orgId } = useContext(AppContext);

    const { data, loading } = useQuery(GET_STAGES_REPORT, {
        variables: {
            period: '',
            organizationId: orgId,
        },
    });
    const { t } = useTranslation('insights');

    if (loading) {
        return <Wrapper>{t('loading')}</Wrapper>;
    }

    const { organizationPathwayStagesReport: report } = data;

    const PERSONAL_STEPS_LABEL = t('personalSteps');
    const STAGE_LABEL = t('stage');

    const graphData = report.map(row => ({
        [PERSONAL_STEPS_LABEL]: row.stepsAddedCount,
        [STAGE_LABEL]: row.pathwayStage.name.toUpperCase(),
    }));

    return (
        <Wrapper>
            <BarChart
                data={graphData}
                keys={[PERSONAL_STEPS_LABEL]}
                indexBy={STAGE_LABEL}
            />
        </Wrapper>
    );
};

export default PersonalStepsAdded;
