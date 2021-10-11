module.exports = {
  extends: ['kengoldfarb'],
  rules: {
	// https://github.com/typescript-eslint/typescript-eslint/blob/master/packages/eslint-plugin/docs/rules/naming-convention.md
	'react/jsx-props-no-spreading': 0,
	'react/prop-types': 0,
	'react/require-default-props': 0,
	'no-await-in-loop': 0,
	'no-restricted-syntax': 0,
	'import/no-extraneous-dependencies': 0,
	'no-console': 0,
    '@typescript-eslint/naming-convention': [
			'error',
			{
				selector: 'variableLike',
				format: ['PascalCase', 'UPPER_CASE', 'camelCase'],
				leadingUnderscore: 'allow'
			},
			{
				selector: 'variable',
				types: ['boolean'],
				format: ['PascalCase'],
				leadingUnderscore: 'allow',
				prefix: ['is', 'should', 'has', 'can', 'did', 'will', 'was']
			}
		]
  },
};