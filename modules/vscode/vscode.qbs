/*
 * MIT License
 *
 * Copyright (c) 2018 Serhii 'GooRoo' Olendarenko
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
*/

import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

Module {
	property path baseDirectory: project.sourceDirectory

	property bool configExists: vscodeChecker.found
	property string configName: '.vscode/c_cpp_properties.json'
	property path configPath: FileInfo.joinPaths(product.vscode.baseDirectory, product.vscode.configName)

	additionalProductTypes: ['vscode.c_cpp_properties']

	Depends { name: 'cpp' }

	Probe {
		id: vscodeChecker
		configure: {
			found = File.exists('.vscode')
		}
	}

	FileTagger {
		patterns: '*.qbs'
		fileTags: ['vscode.qbs']

	}

	Rule {
		multiplex: true

		inputs: ['cpp']
		auxiliaryInputs: ['vscode.qbs']
		requiresInputs: false

		Artifact {
			fileTags: ['vscode.c_cpp_properties']
			filePath: product.vscode.configName
		}

		prepare: /* (project, product, inputs, outputs, input, output, explicitlyDependsOn) => */ {
			var generate = new JavaScriptCommand()
			generate.highlight = 'filegen'

			if (File.exists(product.vscode.configPath)) {
				generate.description = 'VS Code: `' + product.vscode.configName + '` is found. Generating updated include paths list...'
				generate.sourceCode = function () {
					var input = inputs.cpp[0]

					function isMyHostPlatform(name) {
						var mapping = { 'Mac': 'macos', 'Linux': 'linux', 'Win32': 'windows' }
						return input.qbs.hostOS.contains(mapping[name])
					}

					var f = new TextFile(product.vscode.configPath, TextFile.ReadOnly)
					try {
						var c_cpp_properties = JSON.parse(f.readAll())
					} finally {
						f.close()
					}

					for (var c in c_cpp_properties.configurations) {
						var config = c_cpp_properties.configurations[c]
						if (isMyHostPlatform(config.name)) {
							config.includePath = input.cpp.includePaths.uniqueConcat(config.includePath)
							config.defines = input.cpp.defines.uniqueConcat(config.defines)
							config.browse.path = input.cpp.includePaths.uniqueConcat(config.browse.path)
							config.cppStandard = input.cpp.cxxLanguageVersion
							break
						}
					}

					f = new TextFile(output.filePath, TextFile.WriteOnly)
					try {
						f.write(JSON.stringify(c_cpp_properties, null, 4))
						f.writeLine('')
					} finally {
						f.close()
					}
				}
			} else {
				generate.description = 'VS Code: `' + product.vscode.configName + '` does not exist. Skipping include paths update.'
			}

			var overwrite = new JavaScriptCommand()
			overwrite.highlight = 'filegen'
			overwrite.silent = true
			overwrite.description = 'VS Code: Overwriting ' + product.vscode.configName + ' with an updated version'
			overwrite.sourceCode = function () {
				if (!File.move(output.filePath, product.vscode.configName))
					throw "Can't overwrite `" + product.vscode.configName + "`."
			}

			return [generate, overwrite]
		}
	}

	validate: {
		if (!configExists)
			console.info('VS Code: The project is not configured to be used with Visual Studio Code. Skipping.')
	}
}
