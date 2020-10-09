import { ApolloProvider } from '@apollo/client';
import { ThemeProvider } from 'emotion-theming';
import { getSession, Provider } from 'next-auth/client';

import { missionhubTheme } from '../src/missionhubTheme';
import { useApollo } from '../src/apolloClient';
import { Layout } from '../components/layout/Layout';
import { GetServerSideProps, NextComponentType } from 'next';
import {
    AppContextType,
    AppInitialProps,
} from 'next/dist/next-server/lib/utils';
import { AppProps } from 'next/dist/next-server/lib/router/router';

const App: NextComponentType<AppContextType, AppInitialProps, AppProps> = ({
    Component,
    pageProps,
}) => {
    const apolloClient = useApollo(pageProps.initialApolloState);

    return (
        <ThemeProvider theme={missionhubTheme}>
            <Provider session={pageProps.session}>
                <ApolloProvider client={apolloClient}>
                    <Layout>
                        <Component {...pageProps} />
                    </Layout>
                </ApolloProvider>
            </Provider>
        </ThemeProvider>
    );
};

export const getServerSideProps: GetServerSideProps = async (context) => {
    return {
        props: {
            session: await getSession(context),
        },
    };
};

export default App;
