import React from 'react';
import gql from 'graphql-tag';
import { waitForElement } from '@testing-library/react';

import { renderWithContext } from '../../../testUtils';
import Table from '../';
import { GET_CHALLENGES } from '../../../containers/ChallengesPage/queries';

describe('<Table />', () => {
    it('should render properly in loading', async () => {
        const mapRows = () => [['cell1', 'cell2'], ['cell3', 'cell4']];
        const mapPage = () => ({});

        renderWithContext(
            <Table
                query={GET_CHALLENGES}
                headers={['header-1', 'header-2', 'header-3']}
                mapRows={mapRows}
                mapPage={mapPage}
                variables={{}}
            />,
        ).snapshot();
    });

    it('should render properly with data', async () => {
        const mapRows = () => [['cell1', 'cell2'], ['cell3', 'cell4']];
        const mapPage = () => ({});

        const { snapshot, getByText } = renderWithContext(
            <Table
                query={GET_CHALLENGES}
                headers={['header-1', 'header-2', 'header-3']}
                mapRows={mapRows}
                mapPage={mapPage}
                variables={{}}
            />,
            {
                mocks: {
                    Query: () => ({
                        globalCommunityChallenges: () => ({
                            nodes: () => [],
                            pageInfo: () => {},
                        }),
                    }),
                },
                appContext: {
                    orgId: 1,
                },
            },
        );

        await waitForElement(() => getByText('header-1'));
        snapshot();
    });
});
