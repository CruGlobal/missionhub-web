import styled from '@emotion/styled';
import { signOut, useSession } from 'next-auth/client';
import Link from 'next/link';
import { useRouter } from 'next/router';

import logo from './logo.svg';

const HeaderContainer = styled.header`
    background-color: ${({ theme }) => theme.colors.white};
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    align-items: center;
`;

const NavContainer = styled.nav`
    justify-self: start;
    padding: 1em;
`;

const LogoContainer = styled.div`
    justify-self: center;
    padding: 1em;
`;

const UserMenuDropdown = styled.ul`
    visibility: hidden;
    position: absolute;
    left: 0;
    right: 0;
    top: 100%;
    background: ${({ theme }) => theme.colors.white};
    margin: 0;
    padding: 0;
    li {
        list-style-type: none;
        padding: 1em;
    }
`;

const UserMenuContainer = styled.div`
    justify-self: end;
    align-self: stretch;
    position: relative;
    display: flex;
    &:focus-within > ${UserMenuDropdown} {
        visibility: visible;
    }
`;

const UserMenuButton = styled.a`
    display: flex;
    align-items: center;
    padding: 1em;
    &:hover,
    &:active,
    &:focus {
        background: ${({ theme }) => theme.colors.secondary};
        cursor: pointer;
        color: ${({ theme }) => theme.colors.white};
    }
`;

const UserImage = styled.img`
    border-radius: 50%;
    width: 2.3em;
    height: 2.3em;
    margin-left: 1em;
`;

export const Header = () => {
    const router = useRouter();
    const [session, loading] = useSession();

    return (
        <HeaderContainer>
            <NavContainer>
                <Link href="/communities">Communities</Link>
            </NavContainer>
            <LogoContainer>
                <img src={logo} />
            </LogoContainer>
            <UserMenuContainer>
                {loading ? null : session ? (
                    <>
                        <UserMenuButton
                            href="#"
                            onClick={(e) => e.preventDefault()}
                        >
                            {session.user.name}
                            <UserImage src={session.user.image} />
                        </UserMenuButton>
                        <UserMenuDropdown>
                            <li>
                                <a
                                    href="#"
                                    onClick={(e) => {
                                        e.preventDefault();
                                        signOut();
                                        router.push('/');
                                    }}
                                >
                                    Sign out
                                </a>
                            </li>
                        </UserMenuDropdown>
                    </>
                ) : (
                    <UserMenuButton href="/sign-in">Sign In</UserMenuButton>
                )}
            </UserMenuContainer>
        </HeaderContainer>
    );
};
