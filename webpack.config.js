import path from 'path'
import {fileURLToPath} from 'url'
import NodePolyfillPlugin from 'node-polyfill-webpack-plugin'
import glob from 'glob'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const testEntries = glob.sync("./src/**/test__*.coffee").reduce((acc, val) => {
			const filenameRegex = /test__([\w\d_-]*)\.coffee$/i
			acc[val.match(filenameRegex)[1]] = val
			return acc
		}, {})

export default {
	entry: testEntries,
	mode: 'development',

	// Best practice:
	// - Använd 'inline-cheap-module-source-map' som ger rätt radnr i coffee filer och om det kastas ett fel,
	//	 läs i stack trace och försök hitta .coffee filen och radnummret i din kod som är intressant
	//
	// - Om du inte lyckas lista ut vilken rad i .coffee som orsakar felet, byt temporärt till
	//   'cheap-module-source-map' åtgärda felet och byt sen tillbaks
	//
	devtool: 'inline-cheap-module-source-map',
	// devtool: 'cheap-module-source-map',

	// Alla testade för referes och för att kunna kopiera in och snabbt byta till för att testa
	// se sumb.coffee och sumb.test.coffee i git-historik
	// devtool: 'eval', // a.err rad 9 js eval
	// devtool: 'eval-cheap-source-map', // a.err rad 9 js eval
	// devtool: 'eval-cheap-module-source-map', // a.err rad 9 js eval - snabbare än ovan
	// devtool: 'eval-source-map', // a.err rad 9 js eval - 
	// devtool: 'cheap-source-map', // a.err rad 7 .js + .js.map + .js.map + Skriver ut rad för error i js! <---- Bra
	// devtool: 'cheap-module-source-map', // a.err rad 7 .js + .js.map + Skriver ut rad för error i js! <---- Bra
	// devtool: 'source-map', // a.err rad 7 .js + .js.map  + Skriver ut rad för error i js! <---- Bra
	// devtool: 'source-map', // (production), 3.err rad 6 .js + .js.map
	// devtool: 'inline-cheap-module-source-map', // a.err rad 6 .js + klarar if <---- Rätt rad men dålig error
	// devtool: 'inline-source-map', // a.err rad 6 .js
	// devtool: 'eval-nosources-cheap-source-map', // a.err rad 9
	// devtool: 'eval-nosources-cheap-module-source-map', // a.err rad 9
	// devtool: 'eval-nosources-source-map', // a.err rad 9
	// devtool: 'inline-nosources-cheap-source-map', // a.arr rad 7
	// devtool: 'inline-nosources-cheap-module-source-map', // a.arr rad 6 .js + klarar if <---- Rätt rad men dålig error
	// orkar inte testa fler

	output: {
		filename: '[name].test.js',
		path: path.resolve(__dirname, 'temp'),
		clean: true,
	},
	plugins: [
		new NodePolyfillPlugin()
	],
	watch: true,
	module: {
		rules: [
			{
				include: [
					path.resolve(__dirname),
					path.resolve(__dirname, '../comon'),
				],
				exclude: /node_modules|packages/,
				test: /\.coffee$/,
				use: [
					{loader: 'coffee-loader'},
					{loader: path.resolve(__dirname, '../hack/keywordCoffeeLoader.js')},
				]
			},
		],
	},
	target: 'node',
	resolve: {
		extensions: ['.js', '.coffee'],
		alias: {
			comon: path.resolve(__dirname, '../comon')
		}
	},
}
