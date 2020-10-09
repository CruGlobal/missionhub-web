import { signIn, signOut, useSession } from 'next-auth/client';

const Communities = () => {
    const [session, loading] = useSession();
    return (
        <>
            <h1>Communities</h1>
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

export default Communities;
