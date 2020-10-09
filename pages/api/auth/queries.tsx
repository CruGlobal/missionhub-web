import gql from 'graphql-tag';

export const SIGN_IN_WITH_THE_KEY_MUTATION = gql`
    mutation SignInWithTheKey($accessToken: String!) {
        loginWithTheKey(input: { keyAccessToken: $accessToken }) {
            token
        }
    }
`;

export const SIGN_IN_WITH_FACEBOOK_MUTATION = gql`
    mutation SignInWithFacebook($accessToken: String!) {
        loginWithFacebook(input: { fbAccessToken: $accessToken }) {
            token
        }
    }
`;

export const SIGN_IN_WITH_GOOGLE_MUTATION = gql`
    mutation SignInWithGoogle($idToken: String!) {
        loginWithGoogle(input: { idToken: $idToken }) {
            token
        }
    }
`;

export const SIGN_IN_WITH_APPLE_MUTATION = gql`
    mutation SignInWithApple(
        $appleIdToken: String!
        $firstName: String
        $lastName: String
    ) {
        loginWithApple(
            input: {
                appleIdToken: $appleIdToken
                firstName: $firstName
                lastName: $lastName
            }
        ) {
            token
        }
    }
`;
