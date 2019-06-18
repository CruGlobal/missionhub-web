module.exports = {
    roots: ['src/'],
    setupFilesAfterEnv: ['./src/setupTests.js'],
    transform: {
        '^.+\\.js$': 'babel-jest',
        '^.+\\.svg$': 'jest-svg-transformer',
    },
};
