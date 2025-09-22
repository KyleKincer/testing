Class extends Testing

property executedStatements : Collection

Class constructor()
        Super:C1705()

        If (This:C1470.executedStatements=Null:C1517)
                This:C1470.executedStatements:=[]
        End if

Function _performSQLExecution($statement : Text)
        If (This:C1470.executedStatements=Null:C1517)
                This:C1470.executedStatements:=[]
        End if

        This:C1470.executedStatements.push($statement)
