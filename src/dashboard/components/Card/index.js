import styled from '@emotion/styled';
import React from 'react';
import PropTypes from 'prop-types';
import { withTheme } from 'emotion-theming';

const Container = styled.div`
    box-shadow: 0px 2px 12px rgba(0, 0, 0, 0.2);
    background: ${({ theme }) => theme.colors.white};
    border-radius: 8px;
    padding-left: 24px;
    padding-right: 24px;
    padding-top: 43px;
    margin-top: 36px;
`;

const Title = styled.h1`
    font-weight: 300;
    font-size: 36px;
    line-height: 38px;
    color: ${({ theme }) => theme.colors.primary};
    margin-bottom: 12px;
    margin-top: 0px;
`;

const Subtitle = styled.h2`
    font-size: 14px;
    line-height: 20px;
    font-weight: normal;
    color: ${({ theme }) => theme.colors.primary};
    margin-top: 0;
`;

const Content = styled.div`
    padding: ${props => (props.noPadding ? 0 : '25px')};
    margin: ${props => (props.noPadding ? '0 -24px' : '0')};
`;

const Card = props => {
    const { title, subtitle, children, noPadding } = props;
    return (
        <Container>
            <Title>{title}</Title>
            <Subtitle>{subtitle}</Subtitle>
            <Content noPadding={noPadding}>{children}</Content>
        </Container>
    );
};

export default withTheme(Card);

Card.propTypes = {
    title: PropTypes.string,
    subtitle: PropTypes.string,
    children: PropTypes.element,
    noPadding: PropTypes.bool,
};
