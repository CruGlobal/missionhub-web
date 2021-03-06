import styled from '@emotion/styled';
import React, { useState } from 'react';
import { withTheme } from 'emotion-theming';
import moment, { Moment } from 'moment';
import 'react-dates/initialize';
import 'react-dates/lib/css/_datepicker.css';
import { DateRangePicker, FocusedInputShape } from 'react-dates';

import calendar from '../../assets/icons/calendar.svg';

const Container = styled.div`
    display: flex;
    align-items: center;

    .DateRangePicker {
    }

    .DateRangePickerInput {
        display: flex;
    }

    .DateInput {
        width: 108px;
        height: 32px;
        text-align: center;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: #eceef2;
        text-align: center;
        border-radius: 0 16px 16px 0;
        overflow: hidden;
        cursor: pointer;

        &:first-of-type {
            border-radius: 16px 0 0 16px;
            margin-right: 1px;
        }

        &:hover {
            background-color: #e2e2e2;
        }

        input[type='text']:focus {
            background-color: #e2e2e2;
        }
    }

    .DateInput_input {
        height: 100%;
        font-size: 14px;
        line-height: 20px;
        padding: 0;
        background-color: transparent;
        border-color: transparent;
        border-radius: 0;
        text-align: center;
        color: ${({ theme }) => theme.colors.primary};
        cursor: pointer;
    }

    .CalendarDay__selected_span {
        background: ${({ theme }) => theme.colors.highlight};
        color: white;
        border: 1px solid #2fb0d8;
    }

    .CalendarDay__selected {
        background: ${({ theme }) => theme.colors.highlightDarker};
        color: white;
        border: 1px solid #2fb0d8;
    }

    .CalendarDay__selected:hover {
        background: ${({ theme }) => theme.colors.highlightDarker};
        color: white;
    }

    .CalendarDay__hovered_span:hover,
    .CalendarDay__hovered_span {
        background: ${({ theme }) => theme.colors.highlight};
        border: 1px solid #2fb0d8;
        color: white;
    }

    .DateRangePickerInput_arrow {
        display: none;
    }

    .DateInput_fang {
        top: 56px;
    }
`;

const CalendarIcon = styled.div`
    background-image: url(${calendar});
    width: 24px;
    height: 24px;
    margin-right: 12px;
`;

interface Props {
    onDatesChange: (dates: any) => void;
    startDate: Moment | null;
    endDate: Moment | null;
}

const RangePicker = ({ onDatesChange, startDate, endDate }: Props) => {
    const [dates, setDates] = useState({ startDate, endDate });
    const [focus, setFocus] = useState<FocusedInputShape | null>(null);

    const datesChanged = ({
        startDate,
        endDate,
    }: {
        startDate: Moment | null;
        endDate: Moment | null;
    }) => {
        setDates({ startDate, endDate });
        onDatesChange({ startDate, endDate });
    };

    return (
        <Container>
            <CalendarIcon />
            <DateRangePicker
                startDate={dates.startDate}
                startDateId="startDateId"
                endDate={dates.endDate}
                endDateId="endDateId"
                // @ts-ignore
                onDatesChange={datesChanged}
                focusedInput={focus}
                onFocusChange={focusedInput => {
                    setFocus(focusedInput);
                }}
                hideKeyboardShortcutsPanel={true}
                readOnly={true}
                noBorder={true}
                isOutsideRange={day => day.isAfter(moment.now())}
            />
        </Container>
    );
};

export default withTheme(RangePicker);
