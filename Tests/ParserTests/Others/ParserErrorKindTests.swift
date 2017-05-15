/*
   Copyright 2017 Ryuichi Saito, LLC and the Yanagiba project contributors

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

import XCTest

@testable import Parser

class ParserErrorKindTests : XCTestCase {
  func testAttributes() {
    parseProblematic("@ let a = 1", .fatal, .missingAttributeName)
  }

  func testCodeBlock() {
    parseProblematic("defer", .fatal, .leftBraceExpected("code block"))
    parseProblematic("defer { print(i)", .fatal, .rightBraceExpected("code block"))
  }

  func testDeclarations() {
    parseProblematic("class foo { return }", .fatal, .badDeclaration)

    // protocol declaration
    parseProblematic("protocol foo { var }", .fatal, .missingPropertyMemberName)
    parseProblematic("protocol foo { var bar }", .fatal, .missingTypeForPropertyMember)
    parseProblematic("protocol foo { var bar: Bar }", .fatal, .missingGetterSetterForPropertyMember)
    parseProblematic("protocol foo { var bar: Bar { get { return _bar } } }", .fatal, .protocolPropertyMemberWithBody)
    parseProblematic("protocol foo { func foo() { return _foo } }", .fatal, .protocolMethodMemberWithBody)
    parseProblematic("protocol foo { subscript() -> Self {} }", .fatal, .missingProtocolSubscriptGetSetSpecifier)
    parseProblematic("protocol Foo { associatedtype }", .fatal, .missingProtocolAssociatedTypeName)
    parseProblematic("protocol Foo { bar }", .fatal, .badProtocolMember)
    parseProblematic("protocol {}", .fatal, .missingProtocolName)
    parseProblematic("protocol foo ", .fatal, .leftBraceExpected("protocol declaration body"))

    // precedence-group declaration
    parseProblematic("precedencegroup foo { higherThan bar }", .fatal, .missingColonAfterAttributeNameInPrecedenceGroup)
    parseProblematic("precedencegroup foo { higherThan: }", .fatal, .missingPrecedenceGroupRelation("higherThan"))
    parseProblematic("precedencegroup foo { lowerThan: }", .fatal, .missingPrecedenceGroupRelation("lowerThan"))
    parseProblematic("precedencegroup foo { assignment: 1 }", .fatal, .expectedBooleanAfterPrecedenceGroupAssignment)
    parseProblematic("precedencegroup foo { assignment: }", .fatal, .expectedBooleanAfterPrecedenceGroupAssignment)
    parseProblematic("precedencegroup foo { assgnmnt: }", .fatal, .unknownPrecedenceGroupAttribute("assgnmnt"))
    parseProblematic("precedencegroup foo { associativity: }", .fatal, .expectedPrecedenceGroupAssociativity)
    parseProblematic("precedencegroup foo { associativity: up }", .fatal, .expectedPrecedenceGroupAssociativity)
    parseProblematic("precedencegroup foo { return }", .fatal, .expectedPrecedenceGroupAttribute)
    parseProblematic("precedencegroup foo", .fatal, .leftBraceExpected("precedence group declaration"))
    parseProblematic("precedencegroup", .fatal, .missingPrecedenceName)

    // operator declaration
    parseProblematic("infix operator a", .fatal, .expectedValidOperator)
    parseProblematic("infix operator", .fatal, .expectedValidOperator)
    parseProblematic("infix operator ?", .fatal, .expectedValidOperator)
    parseProblematic("operator <!>", .fatal, .operatorDeclarationHasNoFixity)
    parseProblematic("fileprivate operator <!>", .fatal, .operatorDeclarationHasNoFixity)
    parseProblematic("infix operator <!>:", .fatal, .expectedOperatorNameAfterInfixOperator)

    // subscript declaration
    parseProblematic("subscript()", .fatal, .expectedArrowSubscript)

    // extension declaration
    parseProblematic("extension {}", .fatal, .missingExtensionName)
    parseProblematic("extension foo", .fatal, .leftBraceExpected("extension declaration body"))

    // class declaration
    parseProblematic("class {}", .fatal, .missingClassName)
    parseProblematic("class foo", .fatal, .leftBraceExpected("class declaration body"))

    // struct declaration
    parseProblematic("struct {}", .fatal, .missingStructName)
    parseProblematic("struct foo", .fatal, .leftBraceExpected("struct declaration body"))

    // enum declaration
    parseProblematic("indirect enum Foo: String { case a = \"A\" }", .fatal, .indirectWithRawValueStyle)
    parseProblematic("indirect", .fatal, .enumExpectedAfterIndirect)
    parseProblematic("enum Foo { case i = 1 }", .fatal, .missingTypeForRawValueEnumDeclaration)
    parseProblematic("enum Foo { case j(Int) indirect case i = 1 }", .fatal, .indirectWithRawValueStyle)
    parseProblematic("enum Foo: Int { case j = 1 case i(Int) }", .fatal, .unionStyleMixWithRawValueStyle)
    // parseProblematic("enum Foo { @a }", .fatal, .expectedEnumDeclarationCaseMember)
    parseProblematic("enum Foo { case }", .fatal, .expectedCaseName)
    parseProblematic("enum Foo { case = }", .fatal, .expectedCaseName)
    parseProblematic("enum Foo: Int { case i = j }", .fatal, .nonliteralEnumCaseRawValue)
    parseProblematic("enum Foo: Int { case i = 1, j = 2, k(Int) }", .fatal, .unionStyleMixWithRawValueStyle)
    parseProblematic("enum { case foo }", .fatal, .missingEnumName)
    parseProblematic("enum Foo case", .fatal, .leftBraceExpected("enum declaration body"))

    // func declaration
    parseProblematic("func foo(:)", .fatal, .unnamedParameter)
    parseProblematic("func foo(a)", .fatal, .expectedParameterType)
    parseProblematic("func foo", .fatal, .expectedParameterOpenParenthesis)
    parseProblematic("func foo(foo: Foo", .fatal, .expectedParameterCloseParenthesis)
    parseProblematic("prefix prefix func foo()", .error, .duplicatedFunctionModifiers)
    parseProblematic("prefix postfix func foo()", .error, .duplicatedFunctionModifiers)
    parseProblematic("prefix infix func foo()", .error, .duplicatedFunctionModifiers)
    parseProblematic("func ()", .fatal, .missingFunctionName)

    // func declaration
    parseProblematic("typealias", .fatal, .missingTypealiasName)
    parseProblematic("typealias =", .fatal, .missingTypealiasName)
    parseProblematic("typealias foo", .fatal, .expectedEqualInTypealias)

    // var/let declaration
    parseProblematic("var foo: Int { willSet() {} }", .fatal, .expectedAccesorName("willSet"))
    parseProblematic("var foo: Int { didSet() {} }", .fatal, .expectedAccesorName("didSet"))
    parseProblematic("var foo: Int { didSet {} willSet() {} }", .fatal, .expectedAccesorName("willSet"))
    parseProblematic("var foo: Int { willSet {} didSet() {} }", .fatal, .expectedAccesorName("didSet"))
    parseProblematic("var foo: Int { willSet(bar }", .fatal, .expectedAccesorNameCloseParenthesis("willSet"))
    parseProblematic("var foo: Int { didSet(bar }", .fatal, .expectedAccesorNameCloseParenthesis("didSet"))
    // parseProblematic("var foo: Int ( willSet {}}", .fatal, .leftBraceExpected("willSet/didSet block")) // TODO
    // parseProblematic("var foo: Int ( didSet {}}", .fatal, .leftBraceExpected("willSet/didSet block")) // TODO
    parseProblematic("var foo: Int { willSet {}", .fatal, .rightBraceExpected("willSet/didSet block"))
    parseProblematic("var foo: Int { didSet {}", .fatal, .rightBraceExpected("willSet/didSet block"))
    parseProblematic("var foo: Int { set() {}", .fatal, .expectedAccesorName("setter"))
    parseProblematic("var foo: Int { set(bar }", .fatal, .expectedAccesorNameCloseParenthesis("setter"))
    // parseProblematic("var foo: Int ( get {}}", .fatal, .leftBraceExpected("getter/setter block")) // TODO
    // parseProblematic("var foo: Int ( set {}}", .fatal, .leftBraceExpected("getter/setter block")) // TODO
    parseProblematic("var foo: Int { get {}", .fatal, .rightBraceExpected("getter/setter block"))
    parseProblematic("var foo: Int { set {}", .fatal, .rightBraceExpected("getter/setter block"))
    parseProblematic("var foo: Int { set {} }", .fatal, .varSetWithoutGet)

    // import declaration
    parseProblematic("import", .fatal, .missingModuleNameImportDecl)
  }

  static var allTests = [
    ("testAttributes", testAttributes),
    ("testCodeBlock", testCodeBlock),
    ("testDeclarations", testDeclarations),
  ]
}
