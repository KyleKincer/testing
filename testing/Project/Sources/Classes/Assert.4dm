Class constructor()

Function fail($t : Object; $message : Text)
        // Mark the test as failed and optionally log a message
        This:C1470._recordAssertion($t; False:C215; Null:C1517; Null:C1517; $message)
        $t.fail()
        If ($message#"")
                $t.log($message)
        End if

Function areEqual($t : Object; $expected : Variant; $actual : Variant; $message : Text)
        // If values are not equal, fail and log message
        var $passed : Boolean
        $passed:=($expected=$actual)
        This:C1470._recordAssertion($t; $passed; $expected; $actual; $message)
        If (Not:C34($passed))
                If (Count parameters>=4)  // message provided
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: values are not equal")
                End if
        End if

Function isTrue($t : Object; $value : Variant; $message : Text)
        var $passed : Boolean
        $passed:=$value
        This:C1470._recordAssertion($t; $passed; True:C214; $value; $message)
        If (Not:C34($passed))
                If (Count parameters>=3)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: value is not true")
                End if
        End if

Function isFalse($t : Object; $value : Variant; $message : Text)
        var $passed : Boolean
        $passed:=Not:C34($value)
        This:C1470._recordAssertion($t; $passed; False:C215; $value; $message)
        If (Not:C34($passed))
                If (Count parameters>=3)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: value is not false")
                End if
        End if

Function isNull($t : Object; $value : Variant; $message : Text)
        var $passed : Boolean
        $passed:=($value=Null)
        This:C1470._recordAssertion($t; $passed; Null:C1517; $value; $message)
        If (Not:C34($passed))
                If (Count parameters>=3)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: value is not Null")
                End if
        End if

Function isNotNull($t : Object; $value : Variant; $message : Text)
        var $passed : Boolean
        $passed:=($value#Null)
        This:C1470._recordAssertion($t; $passed; "<not null>"; $value; $message)
        If (Not:C34($passed))
                If (Count parameters>=3)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: value is Null")
                End if
        End if

Function contains($t : Object; $container : Variant; $value : Variant; $message : Text)
        var $found : Boolean
        var $type : Integer
        $found:=False
        $type:=Value type:C1509($container)

        Case of
                : ($type=Is text:K8:3)
                        $found:=(Position:C15(String:C10($value); $container)>0)
                : ($type=Is collection:K8:32)
                        $found:=($container.indexOf($value)#-1)
                Else
                        If (Count parameters>=4)
                                This.fail($t; $message)
                        Else
                                This.fail($t; "Assertion failed: unsupported type for contains")
                        End if
                        return
        End case

        This:C1470._recordAssertion($t; $found; $value; $container; $message)
        If (Not:C34($found))
                If (Count parameters>=4)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: container does not contain value")
                End if
        End if

Function _recordAssertion($t : Object; $passed : Boolean; $expected : Variant; $actual : Variant; $message : Text)
        var $cc : Collection
        var $line : Variant
        $cc:=Call chain:C1662
        $line:=Null
        If ($cc.length>1) && ($cc[1].line#Null)
                $line:=$cc[1].line
        End if
        var $assertInfo : Object
        $assertInfo:=New object:C1471(\
                "passed"; $passed; \
                "expected"; $expected; \
                "actual"; $actual; \
                "message"; $message; \
                "line"; $line\
                )
        $t.assertions.push($assertInfo)


