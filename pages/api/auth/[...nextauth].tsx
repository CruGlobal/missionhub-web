import NextAuth from 'next-auth';
import Providers from 'next-auth/providers';

import { initializeApollo } from '../../../src/apolloClient';
import {
    SIGN_IN_WITH_FACEBOOK_MUTATION,
    SIGN_IN_WITH_GOOGLE_MUTATION,
} from './queries';
import {
    SignInWithGoogle,
    SignInWithGoogleVariables,
} from './__generated__/SignInWithGoogle';
import {
    SignInWithFacebook,
    SignInWithFacebookVariables,
} from './__generated__/SignInWithFacebook';

const getMissionHubJwt = async (account) => {
    const apolloClient = initializeApollo();

    switch (account.provider) {
        case 'google':
            return (
                await apolloClient.mutate<
                    SignInWithGoogle,
                    SignInWithGoogleVariables
                >({
                    mutation: SIGN_IN_WITH_GOOGLE_MUTATION,
                    // next-auth was modified with patch-package to expose this
                    variables: { idToken: account.idToken },
                    context: { public: true },
                })
            ).data?.loginWithGoogle?.token;
        case 'facebook':
            return (
                await apolloClient.mutate<
                    SignInWithFacebook,
                    SignInWithFacebookVariables
                >({
                    mutation: SIGN_IN_WITH_FACEBOOK_MUTATION,
                    variables: { accessToken: account.accessToken },
                    context: { public: true },
                })
            ).data?.loginWithFacebook?.token;
    }
};

const options = {
    providers: [
        Providers.Google({
            clientId: process.env.GOOGLE_CLIENT_ID,
            clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        }),
        Providers.Facebook({
            clientId: process.env.FACEBOOK_CLIENT_ID,
            clientSecret: process.env.FACEBOOK_CLIENT_SECRET,
        }),
        Providers.Apple({
            clientId: process.env.APPLE_CLIENT_ID,
            clientSecret: process.env.APPLE_CLIENT_SECRET,
        }),
        {
            id: 'thekey',
            name: 'The Key',
            type: 'oauth',
            version: '2.0',
            scope: 'fullticket',
            params: { grant_type: 'authorization_code' },
            accessTokenUrl: 'https://thekey.me/cas/api/oauth/token',
            authorizationUrl: 'https://thekey.me/cas/login?response_type=code',
            profileUrl: `${process.env.SITE_URL}/api/auth/profile`,
            profile: (profile: Profile): Profile => profile,
            clientId: process.env.THE_KEY_CLIENT_ID,
            clientSecret: process.env.THE_KEY_CLIENT_SECRET,
        },
    ],
    callbacks: {
        jwt: async (token, user, account, profile, isNewUser) => {
            return account
                ? { ...token, missionhubJwt: await getMissionHubJwt(account) }
                : token;
        },
    },
};

export default (req, res) => NextAuth(req, res, options);
