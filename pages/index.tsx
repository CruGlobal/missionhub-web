import React, { ReactElement } from 'react';
import { getSession } from 'next-auth/client';
import { GetServerSideProps } from 'next';

const IndexPage = (): ReactElement => <></>;

export const getServerSideProps: GetServerSideProps = async (context) => {
    const session = await getSession(context);

    if (session) {
        context.res.writeHead(302, { Location: '/communities' });
        context.res.end();
    } else {
        context.res.writeHead(302, { Location: '/sign-in' });
        context.res.end();
    }
    return { props: {} };
};

export default IndexPage;
