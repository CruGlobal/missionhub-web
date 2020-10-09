import { GetServerSideProps, GetServerSidePropsResult } from 'next';
import { getSession, signIn, signOut, useSession } from 'next-auth/client';

const Index = () => {
    const [session, loading] = useSession();
    return (
        <>
            <h1>Sign in</h1>
            {!session && (
                <>
                    Not signed in <br />
                    <button onClick={() => signIn()}>Sign in</button>
                </>
            )}
            {session && (
                <>
                    Signed in as {session.user.email} <br />
                    <button onClick={() => signOut()}>Sign out</button>
                </>
            )}
        </>
    );
};

export const getServerSideProps: GetServerSideProps = async (context) => {
    const session = await getSession(context);

    if (session) {
        context.res.writeHead(302, { Location: '/communities' });
        context.res.end();
    }
    return { props: {} };
};

export default Index;
