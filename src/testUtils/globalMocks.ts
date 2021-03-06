import faker from 'faker/locale/en';
import moment from 'moment';

let currentId = 1;
const nextId = () => currentId++;
export const resetGlobalMockSeeds = () => {
    currentId = 1;
    faker.seed(1);
};
resetGlobalMockSeeds();

export const globalMocks = {
    String: () => faker.lorem.words(),
    Int: () => faker.random.number(),
    Float: () => faker.random.number({ precision: 0.01 }),
    Boolean: () => faker.random.boolean(),
    ID: () => nextId(),
    ISO8601DateTime: () => faker.date.past(10, '2020-01-14').toISOString(),
    ISO8601Date: () =>
        moment(faker.date.past(10, '2020-01-14')).format('YYYY-MM-DD'),

    BasePageInfo: () => ({
        endCursor: null,
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: null,
    }),
    Step: () => ({
        title: faker.lorem.sentence(),
    }),
    Person: () => {
        const firstName = faker.name.firstName();
        const lastName = faker.name.lastName();
        return {
            fullName: `${firstName} ${lastName}`,
            firstName,
            lastName,
        };
    },
};
