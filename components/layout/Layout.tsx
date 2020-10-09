import styled from '@emotion/styled';
import { Global, css } from '@emotion/core';

import { Header } from './Header';
import { useTheme } from 'emotion-theming';
import { MissionHubTheme } from '../../src/missionhubTheme';
import { ReactNode } from 'react';

const Content = styled.div`
    margin: 0 1em;
`;

interface LayoutProps {
    children: ReactNode;
}

export const Layout = ({ children }: LayoutProps) => {
    const theme = useTheme<MissionHubTheme>();

    return (
        <>
            <Global
                styles={css`
                    body {
                        background-color: ${theme.colors.background};
                        color: ${theme.colors.primary};
                        font-family: ${theme.font.family};
                        margin: 0;
                    }
                    a {
                        text-decoration: none;
                    }
                    a,
                    a:visited {
                        color: ${theme.colors.primary};
                    }
                    a:focus,
                    a:hover {
                        color: ${theme.colors.highlight};
                    }
                `}
            />
            <Header />
            <Content>{children}</Content>
        </>
    );
};
