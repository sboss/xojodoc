#tag Class
Protected Class MarkdownWriter
	#tag Method, Flags = &h21
		Private Function GetParent(root As FolderItem, f As XdocFile, ByRef fullName As String) As FolderItem
		  Dim filename As String = f.Name + ".md"
		  
		  If f.ParentId = "" Or f.ParentId = "&h0" Then
		    fullname = f.Name
		    If root Is Nil Then
		      Return Nil
		    End If
		    
		    Return root.Child(filename)
		  End If
		  
		  Dim current As XdocFolder = Project.Folders.Value(f.ParentId)
		  Dim parents() As XdocFolder
		  
		  Do
		    parents.Append current
		    current = Project.Folders.Lookup(current.ParentId, Nil)
		  Loop Until current Is Nil
		  
		  Dim parentNames() As String
		  Dim fh As FolderItem = root
		  
		  For i As Integer = parents.Ubound DownTo 0
		    parentNames.Append parents(i).Name
		    
		    If Not (root Is Nil) Then
		      fh = fh.Child(parents(i).Name)
		      
		      If Not fh.Exists Then
		        fh.CreateAsFolder
		      End If
		    End If
		  Next
		  
		  parentNames.Append f.Name
		  
		  fullName = Join(parentNames, ".")
		  
		  If root Is Nil Then
		    Return Nil
		  End If
		  
		  Return fh.Child(filename)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(path As FolderItem, project As XdocProject, asSingleFile As Boolean = False)
		  Self.Project = project
		  
		  Dim tos As TextOutputStream
		  
		  If asSingleFile Then
		    tos = TextOutputStream.Create(path)
		  End If
		  
		  For Each f As XdocFile In project.Files
		    Dim fullName As String
		    Dim fh As FolderItem = GetParent(If(asSingleFile, Nil, path), f, fullName)
		    
		    If Not asSingleFile Then
		      tos = TextOutputStream.Create(fh)
		    End If
		    
		    tos.WriteLine "# " + f.Type + " " +  fullName
		    tos.WriteLine ""
		    
		    //
		    // We want to print the Overview note first, if available.
		    // Then all other notes in the order they appeared in the
		    // documentation
		    //
		    
		    Dim notes() As XdocNote = f.Notes
		    Dim overviewNote As XdocNote
		    For i As Integer = 0 To notes.Ubound
		      If notes(i).Name = "Overview" Then
		        overviewNote = notes(i)
		        notes.Remove i
		        Exit
		      End If
		    Next
		    
		    If Not (overviewNote Is Nil) Then
		      tos.WriteLine overviewNote.Text
		      tos.WriteLine ""
		    End If
		    
		    If notes.Ubound > -1 Then
		      tos.WriteLine "## Notes"
		      tos.WriteLine ""
		      
		      For i As Integer = 0 To notes.Ubound
		        tos.WriteLine "### " + notes(i).Name
		        tos.WriteLine notes(i).Text
		        tos.WriteLine ""
		      Next
		    End If
		    
		    WriteConstants(f.Constants, tos)
		    
		    If f.Enums.Ubound > -1 Then
		      tos.WriteLine "## Enums"
		      tos.WriteLine ""
		      
		      For i As Integer = 0 To f.Enums.Ubound
		        Dim e As XdocEnum = f.Enums(i)
		        
		        tos.WriteLine "### `" + e.Name + "`"
		        
		        For j As Integer = 0 To e.Values.Ubound
		          tos.WriteLine "* `" + e.Values(j) + "`"
		        Next
		        
		        tos.WriteLine ""
		      Next
		    End If
		    
		    If f.EventDefinitions.Ubound > -1 Then
		      Dim lines() As String
		      
		      For Each m As XdocMethod In f.EventDefinitions
		        Dim line As String = m.Name + "(" + Join(m.Parameters, ", ") + ")"
		        If m.ReturnType <> "" Then
		          line = line + " As " + m.ReturnType
		        End If
		        
		        lines.Append "* `" + line + "`"
		      Next
		      
		      If lines.Ubound > -1 Then
		        tos.WriteLine "## Event Definitions"
		        tos.WriteLine Join(lines, EndOfLine)
		        tos.WriteLine ""
		      End If
		    End If
		    
		    If IncludeEvents Then
		      WriteMethods("Events", f.Events, tos)
		    End If
		    
		    WriteProperties("Properties", f.Properties, tos)
		    WriteMethods("Methods", f.Methods, tos)
		    WriteProperties("Shared Properties", f.SharedProperties, tos)
		    WriteMethods("Shared Methods", f.SharedMethods, tos)
		    
		    If Not asSingleFile Then
		      tos.Close
		    End If
		  Next
		  
		  tos.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteConstants(consts() As XdocConstant, tos As TextOutputStream)
		  Dim lines() As String
		  
		  For i As Integer = 0 To consts.Ubound
		    Dim c As XdocConstant = consts(i)
		    
		    If c.Visibility = XdocProject.kVisibilityPrivate And Not IncludePrivate Then
		      Continue
		    End If
		    
		    If c.Visibility = XdocProject.kVisibilityProtected And Not IncludeProtected Then
		      Continue
		    End If
		    
		    lines.Append "* `" + c.Name + " As " + c.Type + " = " + c.Value + "`"
		  Next
		  
		  If lines.Ubound > -1 Then
		    tos.WriteLine "## Constants"
		    tos.WriteLine Join(lines, EndOfLine)
		    tos.WriteLine ""
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteMethods(sectionTitle As String, meths() As XdocMethod, tos As TextOutputStream)
		  If meths.Ubound > -1 Then
		    Dim methodLines() As String
		    
		    For i As Integer = 0 To meths.Ubound
		      Dim m As XdocMethod = meths(i)
		      
		      If m.Visibility = XdocProject.kVisibilityPrivate And Not IncludePrivate Then
		        Continue
		      End If
		      
		      If m.Visibility = XdocProject.kVisibilityProtected And Not IncludeProtected Then
		        Continue
		      End If
		      
		      Dim methodLine As String = m.Name + "(" + Join(m.Parameters, ", ") + ")"
		      If m.ReturnType <> "" Then
		        methodLine = methodLine + " As " + m.ReturnType
		      End If
		      
		      methodLines.Append "### `" + methodLine + "`"
		      methodLines.Append m.Notes
		      methodLines.Append ""
		    Next
		    
		    If methodLines.Ubound > -1 Then
		      tos.WriteLine "## " + sectionTitle
		      tos.WriteLine ""
		      tos.WriteLine Join(methodLines, EndOfLine)
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteProperties(sectionTitle As String, props() As XdocProperty, tos As TextOutputStream)
		  If props.Ubound > -1 Then
		    Dim lines() As String
		    
		    For i As Integer = 0 To props.Ubound
		      Dim p As XdocProperty = props(i)
		      
		      If p.Visibility = XdocProject.kVisibilityPrivate And Not IncludePrivate Then
		        Continue
		      End If
		      
		      If p.Visibility = XdocProject.kVisibilityProtected And Not IncludeProtected Then
		        Continue
		      End If
		      
		      lines.Append "### `" + p.Declaration + "`"
		      lines.Append ""
		      
		      If p.Note <> "" Then
		        lines.Append p.Note
		      End If
		      
		      lines.Append ""
		    Next
		    
		    If lines.Ubound > -1 Then
		      tos.WriteLine "## " + sectionTitle
		      tos.WriteLine ""
		      tos.WriteLine Join(lines, EndOfLine)
		    End If
		  End If
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		IncludeEvents As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		IncludePrivate As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		IncludeProtected As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Project As XdocProject
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
