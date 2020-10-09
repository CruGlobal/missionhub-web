import {
    ApolloClient,
    InMemoryCache,
    HttpLink,
    ApolloLink,
    NormalizedCacheObject,
} from '@apollo/client';

import defaults from './communityInsights/state/defaults';
import resolvers from './communityInsights/resolvers';
import { useMemo } from 'react';

const cache = new InMemoryCache();
// const stateLink = withClientState({
//     cache,
//     defaults,
//     resolvers,
// });

const authLink = new ApolloLink((operation, forward) => {
    const authToken = 'unimplemented auth token';
    if (authToken && !operation.getContext().public) {
        operation.setContext({
            headers: { authorization: `Bearer ${authToken}` },
        });
    }
    return forward(operation).map((data) => {
        const sessionHeader = operation
            .getContext()
            .response.headers.get('X-MH-Session');

        // Placeholder fn
        const setAuthToken = (authToken: string) => {};
        sessionHeader && setAuthToken(sessionHeader);
        return data;
    });
});

const httpLink = new HttpLink({
    uri: 'https://api-stage.missionhub.com/apis/graphql',
});

let apolloClient: ApolloClient<NormalizedCacheObject>;

const createApolloClient = () =>
    new ApolloClient({
        cache,
        link: ApolloLink.from([
            // stateLink,
            authLink,
            httpLink,
        ]),
        ssrMode: typeof window === 'undefined',
    });

export const initializeApollo = (initialState?: NormalizedCacheObject) => {
    const _apolloClient = apolloClient ?? createApolloClient();

    // If your page has Next.js data fetching methods that use Apollo Client, the initial state
    // gets hydrated here
    if (initialState) {
        // Get existing cache, loaded during client side data fetching
        const existingCache = _apolloClient.extract();
        // Restore the cache using the data passed from getStaticProps/getServerSideProps
        // combined with the existing cached data
        _apolloClient.cache.restore({
            ...existingCache,
            ...initialState,
        });
    }
    // For SSG and SSR always create a new Apollo Client
    if (typeof window === 'undefined') return _apolloClient;
    // Create the Apollo Client once in the client
    if (!apolloClient) apolloClient = _apolloClient;

    return _apolloClient;
};

export function useApollo(initialState?: NormalizedCacheObject) {
    const store = useMemo(() => initializeApollo(initialState), [initialState]);
    return store;
}
