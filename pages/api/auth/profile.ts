import { NextApiRequest, NextApiResponse } from 'next';
import { gql } from '@apollo/client';
import { initializeApollo } from '../../../src/apolloClient';
import { SIGN_IN_WITH_THE_KEY_MUTATION } from './queries';
import {
    SignInWithTheKey,
    SignInWithTheKeyVariables,
} from './__generated__/SignInWithTheKey';

export interface Profile {
    token: string;
}

const profile = async (
    req: NextApiRequest,
    res: NextApiResponse<Profile>,
): Promise<void> => {
    if (!req.headers.authorization) {
        throw new Error(
            'Missing Authorization header for fetching The Key ticket',
        );
    }
    const apolloClient = initializeApollo();

    const {
        data: { ticket },
    } = await (
        await fetch(
            `https://thekey.me/cas/api/oauth/ticket?service${process.env.API_URI}/auth/thekey`,
            {
                headers: {
                    Authorization: req.headers.authorization,
                    Accept: 'application/json',
                },
            },
        )
    ).json();

    const { data } = await apolloClient.mutate<
        SignInWithTheKey,
        SignInWithTheKeyVariables
    >({
        mutation: SIGN_IN_WITH_THE_KEY_MUTATION,
        variables: {
            accessToken: ticket,
        },
    });
    const token = data?.loginWithTheKey?.token;

    if (!token) {
        throw new Error(
            'API failed to return token after sign in with The Key',
        );
    }

    res.status(200).json({ token });
};

export default profile;
