------------------------------------------------------------------------------
--                                                                          --
--                            POLYORB COMPONENTS                            --
--                                   IAC                                    --
--                                                                          --
--                  B A C K E N D . B E _ A D A . C D R S                   --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                           Copyright (c) 2005                             --
--            Ecole Nationale Superieure des Telecommunications             --
--                                                                          --
-- IAC is free software; you  can  redistribute  it and/or modify it under  --
-- terms of the GNU General Public License  as published by the  Free Soft- --
-- ware  Foundation;  either version 2 of the liscence or (at your option)  --
-- any  later version.                                                      --
-- IAC is distributed  in the hope that it will be  useful, but WITHOUT ANY --
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or        --
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for --
-- more details.                                                            --
-- You should have received a copy of the GNU General Public License along  --
-- with this program; if not, write to the Free Software Foundation, Inc.,  --
-- 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.            --
--                                                                          --
------------------------------------------------------------------------------

with Namet;     use Namet;
with Types;     use Types;
with Locations; use Locations;

with Frontend.Nodes;  use Frontend.Nodes;
with Frontend.Nutils;

with Backend.BE_Ada.Nodes;       use Backend.BE_Ada.Nodes;
with Backend.BE_Ada.Nutils;      use Backend.BE_Ada.Nutils;
with Backend.BE_Ada.IDL_To_Ada;  use Backend.BE_Ada.IDL_To_Ada;
with Backend.BE_Ada.Runtime;     use Backend.BE_Ada.Runtime;
with Backend.BE_Ada.Expand;      use Backend.BE_Ada.Expand;

package body Backend.BE_Ada.CDRs is

   package FEN renames Frontend.Nodes;
   package FEU renames Frontend.Nutils;
   package BEN renames Backend.BE_Ada.Nodes;
   package BEU renames Backend.BE_Ada.Nutils;

   package body Package_Spec is

      function Args_Type_Record (E : Node_Id) return Node_Id;
      function Marshaller_Spec (E : Node_Id) return Node_Id;
      function Unmarshaller_Spec (E : Node_Id) return Node_Id;
      function Set_Args_Spec (E : Node_Id) return Node_Id;

      procedure Visit_Attribute_Declaration (E : Node_Id);
      procedure Visit_Interface_Declaration (E : Node_Id);
      procedure Visit_Module (E : Node_Id);
      procedure Visit_Operation_Declaration (E : Node_Id);
      procedure Visit_Specification (E : Node_Id);

      ----------------------
      -- Args_Type_Record --
      ----------------------

      function Args_Type_Record (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);
         Spec       : constant Node_Id := Stub_Node
           (BE_Node (Identifier (E)));
         P          : constant List_Id := Parameter_Profile (Spec);
         T          : constant Node_Id := Return_Type (Spec);
         Components : List_Id;
         Component  : Node_Id;
         Parameter  : Node_Id;
         Args_Type  : Node_Id := No_Node;
      begin
         Components := New_List (K_Component_List);

         --  For each parameter in the subprogram profile, a member with the
         --  same name and the same type is generated in the record

         if not BEU.Is_Empty (P) then

            --  Skip the first parameter corresponding to 'Self'

            Parameter := Next_Node (First_Node (P));
            while Present (Parameter) loop
               Component := Make_Component_Declaration
                 (Defining_Identifier => Defining_Identifier (Parameter),
                  Subtype_Indication  => Parameter_Type (Parameter));
               Append_Node_To_List (Component, Components);
               Parameter := Next_Node (Parameter);
            end loop;
         end if;

         --  If the subprogram is a function, we add an additional member
         --  corresponding to the result of the function.

         if Present (T) and then FEN.Kind (T) /= K_Void then
            Component := Make_Component_Declaration
              (Defining_Identifier => Make_Defining_Identifier
               (PN (P_Returns)),
               Subtype_Indication  => T);
            Append_Node_To_List (Component, Components);
         end if;

         --  Type Declaration

         Args_Type := Make_Full_Type_Declaration
           (Defining_Identifier => Map_Args_Type_Identifier
            (Defining_Identifier (Spec)),
            Type_Definition     => Make_Derived_Type_Definition
            (Subtype_Indication    => RE (RE_Request_Args),
             Record_Extension_Part => Make_Record_Definition
             (Components)));

         Set_Correct_Parent_Unit_Name
           (Defining_Identifier (Args_Type),
            Defining_Identifier (CDR_Package (Current_Entity)));

         return Args_Type;
      end Args_Type_Record;

      ---------------------
      -- Marshaller_Spec --
      ---------------------

      function Marshaller_Spec (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);
         Spec       : constant Node_Id := Stub_Node
           (BE_Node (Identifier (E)));
         Profile   : List_Id;
         Parameter : Node_Id;
         S         : Node_Id;
      begin
         Profile  := New_List (K_Parameter_Profile);

         --  Role parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Role)),
            Subtype_Mark        => RE (RE_Entity_Role),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Args parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Args)),
            Subtype_Mark        => RE (RE_Request_Args_Access),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Buffer parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Buffer)),
            Subtype_Mark        => RE (RE_Buffer_Access),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Representation parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Representation)),
            Subtype_Mark        => Make_Attribute_Designator
            (RE (RE_CDR_Representation), A_Class),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  First_Arg_Alignment parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_First_Arg_Alignment)),
            Subtype_Mark        => RE (RE_Alignment_Type),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Error parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Error)),
            Subtype_Mark        => RE (RE_Error_Container),
            Parameter_Mode      => Mode_Inout);
         Append_Node_To_List (Parameter, Profile);

         --  Subprogram Specification

         S := Make_Subprogram_Specification
           (Map_Marshaller_Identifier (Defining_Identifier (Spec)),
            Profile,
            No_Node);
         Set_Correct_Parent_Unit_Name
           (Defining_Identifier (S),
            Defining_Identifier (CDR_Package (Current_Entity)));

         return S;
      end Marshaller_Spec;

      -----------------------
      -- Unmarshaller_Spec --
      -----------------------

      function Unmarshaller_Spec (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);
         Spec       : constant Node_Id := Stub_Node
           (BE_Node (Identifier (E)));
         Profile   : List_Id;
         Parameter : Node_Id;
         S         : Node_Id;
      begin
         Profile  := New_List (K_Parameter_Profile);

         --  Role parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Role)),
            Subtype_Mark        => RE (RE_Entity_Role),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Args parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Args)),
            Subtype_Mark        => RE (RE_Request_Args_Access),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Buffer parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Buffer)),
            Subtype_Mark        => RE (RE_Buffer_Access),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Representation parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Representation)),
            Subtype_Mark        => Make_Attribute_Designator
            (RE (RE_CDR_Representation), A_Class),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  First_Arg_Alignment parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_First_Arg_Alignment)),
            Subtype_Mark        => RE (RE_Alignment_Type),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Error parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Error)),
            Subtype_Mark        => RE (RE_Error_Container),
            Parameter_Mode      => Mode_Inout);
         Append_Node_To_List (Parameter, Profile);

         --  Subprogram Specification

         S := Make_Subprogram_Specification
           (Map_Unmarshaller_Identifier (Defining_Identifier (Spec)),
            Profile,
            No_Node);
         Set_Correct_Parent_Unit_Name
           (Defining_Identifier (S),
            Defining_Identifier (CDR_Package (Current_Entity)));

         return S;
      end Unmarshaller_Spec;

      -------------------
      -- Set_Args_Spec --
      -------------------

      function Set_Args_Spec (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);
         Spec       : constant Node_Id := Stub_Node
           (BE_Node (Identifier (E)));
         Profile   : List_Id;
         Parameter : Node_Id;
         S         : Node_Id;
      begin
         Profile  := New_List (K_Parameter_Profile);

         --  Request parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Request)),
            Subtype_Mark        => RE (RE_Request_Access),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Args parameter

         Parameter := Make_Parameter_Specification
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Args)),
            Subtype_Mark        => Make_Access_Type_Definition
            (Expand_Designator
             (Type_Def_Node
              (BE_Node
               (Identifier
                (E))))),
            Parameter_Mode      => Mode_In);
         Append_Node_To_List (Parameter, Profile);

         --  Subprogram Specification

         S := Make_Subprogram_Specification
           (Map_Set_Args_Identifier (Defining_Identifier (Spec)),
            Profile,
            No_Node);
         Set_Correct_Parent_Unit_Name
           (Defining_Identifier (S),
            Defining_Identifier (CDR_Package (Current_Entity)));

         return S;
      end Set_Args_Spec;

      -----------
      -- Visit --
      -----------

      procedure Visit (E : Node_Id) is
      begin
         case FEN.Kind (E) is

            when K_Attribute_Declaration =>
               Visit_Attribute_Declaration (E);

            when K_Interface_Declaration =>
               Visit_Interface_Declaration (E);

            when K_Module =>
               Visit_Module (E);

            when K_Operation_Declaration =>
               Visit_Operation_Declaration (E);

            when K_Specification =>
               Visit_Specification (E);

            when others =>
               null;

         end case;
      end Visit;

      ---------------------------------
      -- Visit_Attribute_Declaration --
      ---------------------------------

      procedure Visit_Attribute_Declaration (E : Node_Id) is
         N    : Node_Id;
         D    : Node_Id;
      begin
         Set_CDR_Spec;

         D := First_Entity (Declarators (E));
         while Present (D) loop

            --  Explaining comment

            Set_Str_To_Name_Buffer
              ("Attribute : ");
            Get_Name_String_And_Append (IDL_Name (Identifier (D)));
            N := Make_Ada_Comment (Name_Find);
            Append_Node_To_List (N, Visible_Part (Current_Package));

            D := Next_Entity (D);
         end loop;
      end Visit_Attribute_Declaration;

      ---------------------------------
      -- Visit_Interface_Declaration --
      ---------------------------------

      procedure Visit_Interface_Declaration (E : Node_Id) is
         N : Node_Id;
      begin
         --  No CDR package is generated for a local interface

         if FEN.Is_Local_Interface (E) then
            return;
         end if;

         N := BEN.Parent (Type_Def_Node (BE_Node (Identifier (E))));
         Push_Entity (BEN.IDL_Unit (Package_Declaration (N)));
         Set_CDR_Spec;

         N := First_Entity (Interface_Body (E));
         while Present (N) loop
            Visit (N);
            N := Next_Entity (N);
         end loop;

         Pop_Entity;
      end Visit_Interface_Declaration;

      ------------------
      -- Visit_Module --
      ------------------

      procedure Visit_Module (E : Node_Id) is
         D : Node_Id;
      begin
         if not Map_Particular_CORBA_Parts (E, PK_CDR_Spec) then
            Push_Entity (Stub_Node (BE_Node (Identifier (E))));
            D := First_Entity (Definitions (E));
            while Present (D) loop
               Visit (D);
               D := Next_Entity (D);
            end loop;
            Pop_Entity;
         end if;
      end  Visit_Module;

      ---------------------------------
      -- Visit_Operation_Declaration --
      ---------------------------------

      procedure Visit_Operation_Declaration (E : Node_Id) is
         N    : Node_Id;
      begin
         Set_CDR_Spec;

         --  Explaining comment

         Set_Str_To_Name_Buffer
           ("Operation : ");
         Get_Name_String_And_Append (IDL_Name (Identifier (E)));
         N := Make_Ada_Comment (Name_Find);
         Append_Node_To_List (N, Visible_Part (Current_Package));

         --  Generating the 'Operation_Name'_Args_Type declaration

         N := Args_Type_Record (E);
         Append_Node_To_List (N, Visible_Part (Current_Package));
         Bind_FE_To_Type_Def (Identifier (E), N);

         --  Generating the 'Operation_Name'_Unmarshaller spec

         N := Unmarshaller_Spec (E);
         Append_Node_To_List (N, Visible_Part (Current_Package));
         Bind_FE_To_Unmarshaller (Identifier (E), N);

         --  Generating the 'Operation_Name'_Marshaller spec

         N := Marshaller_Spec (E);
         Append_Node_To_List (N, Visible_Part (Current_Package));
         Bind_FE_To_Marshaller (Identifier (E), N);

         --  Generating the 'Operation_Name'_Set_Args spec

         N := Set_Args_Spec (E);
         Append_Node_To_List (N, Visible_Part (Current_Package));
         Bind_FE_To_Set_Args (Identifier (E), N);

      end Visit_Operation_Declaration;

      -------------------------
      -- Visit_Specification --
      -------------------------

      procedure Visit_Specification (E : Node_Id) is
         Definition : Node_Id;
      begin
         Push_Entity (Stub_Node (BE_Node (Identifier (E))));
         Definition := First_Entity (Definitions (E));
         while Present (Definition) loop
            Visit (Definition);
            Definition := Next_Entity (Definition);
         end loop;
         Pop_Entity;
      end Visit_Specification;
   end Package_Spec;

   package body Package_Body is

      function Marshaller_Body (E : Node_Id) return Node_Id;
      function Unmarshaller_Body (E : Node_Id) return Node_Id;
      function Set_Args_Body (E : Node_Id) return Node_Id;

      --  This subprogram returns the original type of the given parameter.
      --  The node given as a parameter is a node of the IDL tree and
      --  the returned node is also a node from the IDL tree. This function
      --  returns also declarators list of the type (appended into the
      --  Declarators list)
      function Get_Original_Type
        (Parameter   : Node_Id;
         Declarators : List_Id := No_List)
        return Node_Id;

      --  This function builds a variable declaration. The variable corresponds
      --  to an operation parameter or an operation result. The variable type
      --  is the PolyORB corresponding to the Var_Type node
      function Storage_Variable_Declaration
        (Var_Name : Name_Id; Var_Node : Node_Id)
        return Node_Id;

      --  This function builds a type conversion of a variable from a PolyORB
      --  type into a CORBA type
      function Cast_Variable_From_PolyORB_Type
        (Var_Name : Name_Id; Var_Node : Node_Id)
        return Node_Id;

      --  This function builds a type conversion of a variable to a PolyORB
      --  type
      function Cast_Variable_To_PolyORB_Type
        (Var_Node : Node_Id; Type_Dcl : Node_Id)
        return Node_Id;

      --  This function builds the unmarshalling statements from the buffer
      --  into the variable var_name
      function Do_Unmarshall
        (Var_Name : Name_Id;
         Var_Type : Node_Id;
         Buff     : Name_Id)
        return Node_Id;

      --  This function builds the marshalling statements to the buffer
      --  from the variable var_name
      function Do_Marshall
        (Var_Node : Node_Id;
         Var_Type : Node_Id;
         Buff     : Name_Id)
        return Node_Id;

      --  This function tests wether the mode is IN or INOUT
      function Is_In (Par_Mode : Mode_Id) return Boolean;

      --  This function tests wether the mode is OUT or INOUT
      function Is_Out (Par_Mode : Mode_Id) return Boolean;

      --  The two subprogram below use the two subprogram above to chack the
      --  parameter mode of an IDL operation
      function Contains_In_Parameters (E : Node_Id) return Boolean;
      function Contains_Out_Parameters (E : Node_Id) return Boolean;

      procedure Visit_Attribute_Declaration (E : Node_Id);
      procedure Visit_Interface_Declaration (E : Node_Id);
      procedure Visit_Module (E : Node_Id);
      procedure Visit_Operation_Declaration (E : Node_Id);
      procedure Visit_Specification (E : Node_Id);

      ---------------------
      -- Marshaller_Body --
      ---------------------

      function Marshaller_Body (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);

         Subp_Spec         : Node_Id;
         Subp_Statements   : constant List_Id := New_List (K_List_Id);
         Subp_Declarations : constant List_Id := New_List (K_List_Id);

         P                 : constant List_Id := Parameters (E);
         T                 : constant Node_Id := Type_Spec (E);

         Client_Case       : constant List_Id := Make_List_Id
           (RE (RE_Client_Entity));
         Client_Statements : constant List_Id := New_List (K_List_Id);

         Server_Case       : constant List_Id := Make_List_Id
           (RE (RE_Server_Entity));
         Server_Statements : constant List_Id := New_List (K_List_Id);

         Case_Alternatives : constant List_Id := New_List (K_List_Id);

         Args_Id           : Node_Id;
         Parameter         : Node_Id;
         Parameter_Name    : Name_Id;
         Parameter_Mode    : Mode_Id;
         Rewinded_Type     : Node_Id;
         N                 : Node_Id;
         M                 : Node_Id;

         --  The global structure of the generated XXXX_Marshaller
         --  function is :
         --  case Role is
         --     when Client_Entity =>
         --        <Marshall IN and INOUT Arguments> (if exist)
         --     when Server_Entity =>
         --        <Marshall Result> (if exists)
         --        <Marshall OUT and INOUT Arguments> (if exist)
         --  end case;

      begin
         Subp_Spec := Marshaller_Node (BE_Node (Identifier (E)));
         Args_Id   := Map_Args_Identifier
           (Defining_Identifier
            (Stub_Node
             (BE_Node
              (Identifier
               (E)))));

         --  Common declarations

         N := Make_Object_Declaration
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Data_Alignment)),
            Object_Definition   => RE (RE_Alignment_Type),
            Constant_Present    => not Contains_Out_Parameters (E),
            Expression          => Make_Designator
            (PN (P_First_Arg_Alignment)));
         Append_Node_To_List (N, Subp_Declarations);

         N := Expand_Designator
           (Type_Def_Node
            (BE_Node
             (Identifier
              (E))));
         M := Make_Designator
           (Designator => PN (P_Args),
            Is_All     => True);
         N := Make_Object_Declaration
           (Defining_Identifier => Args_Id,
            Object_Definition   => N,
            Expression          => Make_Subprogram_Call
            (N, Make_List_Id (M)));
         Append_Node_To_List (N, Subp_Declarations);

         --  If the subprogram is a function, we handle the result

         if Present (T) and then FEN.Kind (T) /= K_Void then

            Rewinded_Type := Get_Original_Type (E);

            --  Explaining comment

            Set_Str_To_Name_Buffer
              ("Marshalling Result    : ");
            Get_Name_String_And_Append  (PN (P_Returns));
            Add_Str_To_Name_Buffer (" => ");
            Add_Str_To_Name_Buffer
              (FEN.Node_Kind'Image
               (FEN.Kind
                (Rewinded_Type)));
            N := Make_Ada_Comment (Name_Find);
            Append_Node_To_List (N, Server_Statements);

            --  Aligning CDR position in Buffer

            N := Make_Subprogram_Call
              (RE (RE_Pad_Align),
               Make_List_Id
               (Make_Designator (PN (P_Buffer)),
                Make_Designator (PN (P_Data_Alignment))));
            Append_Node_To_List (N, Server_Statements);

            --  the operation does not have out or inout parameters, there is
            --  no need to this
            if Contains_Out_Parameters (E) then
               N := Make_Assignment_Statement
                 (Make_Defining_Identifier (PN (P_Data_Alignment)),
                  Make_Literal (Int1_Val));
               Append_Node_To_List (N, Server_Statements);
            end if;

            --  Marshalling the result and handling the error

            N := Make_Defining_Identifier (PN (P_Returns));
            Set_Correct_Parent_Unit_Name (N, Copy_Node (Args_Id));

            N := Do_Marshall (N, E, PN (P_Buffer));
            Append_Node_To_List (N, Server_Statements);

         end if;

         --  Handling parameters

         if not FEU.Is_Empty (P) then

            --  Aligning CDR position in Buffer in client and server parts

            if Contains_Out_Parameters (E) then
               N := Make_Subprogram_Call
                 (RE (RE_Pad_Align),
                  Make_List_Id
                  (Make_Designator (PN (P_Buffer)),
                   Make_Designator (PN (P_Data_Alignment))));
               Append_Node_To_List (N, Server_Statements);
            end if;

            if Contains_In_Parameters (E) then
               N := Make_Subprogram_Call
                 (RE (RE_Pad_Align),
                  Make_List_Id
                  (Make_Designator (PN (P_Buffer)),
                   Make_Designator (PN (P_Data_Alignment))));
               Append_Node_To_List (N, Client_Statements);
            end if;

            --  Skip the first parameter corresponding to 'Self'

            Parameter := First_Entity (P);
            while Present (Parameter) loop

               Rewinded_Type  := Get_Original_Type (Parameter);
               Parameter_Name := To_Ada_Name
                 (IDL_Name
                  (Identifier
                   (Declarator
                    (Parameter))));
               Parameter_Mode := FEN.Parameter_Mode (Parameter);

               --  The IN    parameters are marshalled by client
               --  The OUT   parameters are marshalled by server
               --  The INOUT parameters are marshalled by client and server

               --  Explaining comment

               Set_Str_To_Name_Buffer
                 ("Marshall Parameter : ");
               Get_Name_String_And_Append (Parameter_Name);
               Add_Str_To_Name_Buffer (" => ");
               Add_Str_To_Name_Buffer
                 (FEN.Node_Kind'Image
                  (FEN.Kind
                   (Get_Original_Type
                    (Parameter))));

               if Is_In (Parameter_Mode) then
                  N := Make_Ada_Comment (Name_Find);
                  Append_Node_To_List (N, Client_Statements);
               end if;
               if Is_Out (Parameter_Mode) then
                  N := Make_Ada_Comment (Name_Find);
                  Append_Node_To_List (N, Server_Statements);
               end if;

               --  Marshalling the parameter and handling the error

               if Is_In (Parameter_Mode) then
                  N := Make_Defining_Identifier (Parameter_Name);
                  Set_Correct_Parent_Unit_Name (N, Copy_Node (Args_Id));
                  N := Do_Marshall
                    (N,
                     Parameter,
                     PN (P_Buffer));
                  Append_Node_To_List (N, Client_Statements);
               end if;
               if Is_Out (Parameter_Mode) then
                  N := Make_Defining_Identifier (Parameter_Name);
                  Set_Correct_Parent_Unit_Name (N, Copy_Node (Args_Id));
                  N := Do_Marshall
                    (N,
                     Parameter,
                     PN (P_Buffer));
                  Append_Node_To_List (N, Server_Statements);
               end if;

               Parameter := Next_Entity (Parameter);
            end loop;
         end if;

         --  Building the case statement

         if BEU.Is_Empty (Client_Statements) then
            Append_Node_To_List (Make_Null_Statement, Client_Statements);
         end if;
         N := Make_Case_Statement_Alternative (Client_Case, Client_Statements);
         Append_Node_To_List (N, Case_Alternatives);

         if BEU.Is_Empty (Server_Statements) then
            Append_Node_To_List (Make_Null_Statement, Server_Statements);
         end if;
         N := Make_Case_Statement_Alternative (Server_Case, Server_Statements);
         Append_Node_To_List (N, Case_Alternatives);

         N := Make_Case_Statement
           (Make_Designator (PN (P_Role)), Case_Alternatives);
         Append_Node_To_List (N, Subp_Statements);

         --  Building the subprogram implementation

         N := Make_Subprogram_Implementation
           (Specification => Subp_Spec,
            Declarations  => Subp_Declarations,
            Statements    => Subp_Statements);
         return N;
      end Marshaller_Body;

      -----------------------
      -- Unmarshaller_Body --
      -----------------------

      function Unmarshaller_Body (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);

         Subp_Spec         : Node_Id;
         Subp_Statements   : constant List_Id := New_List (K_List_Id);
         Subp_Declarations : constant List_Id := New_List (K_List_Id);

         P                 : constant List_Id := Parameters (E);
         T                 : constant Node_Id := Type_Spec (E);

         Client_Case       : constant List_Id := Make_List_Id
           (RE (RE_Client_Entity));
         Client_Statements : constant List_Id := New_List (K_List_Id);

         Server_Case       : constant List_Id := Make_List_Id
           (RE (RE_Server_Entity));
         Server_Statements : constant List_Id := New_List (K_List_Id);

         Case_Alternatives : constant List_Id := New_List (K_List_Id);

         Args_Id           : Node_Id;
         Parameter         : Node_Id;
         Parameter_Name    : Name_Id;
         Parameter_Mode    : Mode_Id;
         Rewinded_Type     : Node_Id;
         N                 : Node_Id;
         M                 : Node_Id;

         --  The global structure of the generated XXXX_Unmarshaller
         --  function is :
         --  case Role is
         --     when Client_Entity =>
         --        <Unmarshall Result> (if exists)
         --        <Unmarshall OUT and INOUT Arguments> (if exist)
         --     when Server_Entity =>
         --        <Unmarshall IN and INOUT Arguments> (if exist)
         --  end case;

      begin
         Subp_Spec := Unmarshaller_Node (BE_Node (Identifier (E)));
         Args_Id   := Map_Args_Identifier
           (Defining_Identifier
            (Stub_Node
             (BE_Node
              (Identifier
               (E)))));

         --  Common declarations

         N := Make_Object_Declaration
           (Defining_Identifier => Make_Defining_Identifier
            (PN (P_Data_Alignment)),
            Object_Definition   => RE (RE_Alignment_Type),
            Constant_Present    => not Contains_Out_Parameters (E),
            Expression          => Make_Designator
            (PN (P_First_Arg_Alignment)));
         Append_Node_To_List (N, Subp_Declarations);

         N := Expand_Designator
           (Type_Def_Node
            (BE_Node
             (Identifier
              (E))));
         M := Make_Designator
           (Designator => PN (P_Args),
            Is_All     => True);
         N := Make_Object_Declaration
           (Defining_Identifier => Args_Id,
            Object_Definition   => N,
            Expression          => Make_Subprogram_Call
            (N, Make_List_Id (M)));
         Append_Node_To_List (N, Subp_Declarations);

         --  If the subprogram is a function, we handle the result

         if Present (T) and then FEN.Kind (T) /= K_Void then

            Rewinded_Type := Get_Original_Type (E);

            --  Explaining comment

            Set_Str_To_Name_Buffer
              ("Unmarshalling Result    : ");
            Get_Name_String_And_Append  (PN (P_Returns));
            Add_Str_To_Name_Buffer (" => ");
            Add_Str_To_Name_Buffer
              (FEN.Node_Kind'Image
               (FEN.Kind
                (Rewinded_Type)));
            N := Make_Ada_Comment (Name_Find);
            Append_Node_To_List (N, Client_Statements);

            --  Aligning CDR position in Buffer

            N := Make_Subprogram_Call
              (RE (RE_Align_Position),
               Make_List_Id
               (Make_Designator (PN (P_Buffer)),
                Make_Designator (PN (P_Data_Alignment))));
            Append_Node_To_List (N, Client_Statements);

            --  the operation does not have out or inout parameters, there is
            --  no need to this
            if Contains_Out_Parameters (E) then
               N := Make_Assignment_Statement
                 (Make_Defining_Identifier (PN (P_Data_Alignment)),
                  Make_Literal (Int1_Val));
               Append_Node_To_List (N, Client_Statements);
            end if;

            --  Declaring the storage variable

            N := Storage_Variable_Declaration
              (PN (P_Returns), E);
            Append_Node_To_List (N, Subp_Declarations);

            --  Unmarshalling the result and handling the error

            N := Do_Unmarshall (PN (P_Returns), E, PN (P_Buffer));
            Append_Node_To_List (N, Client_Statements);

            --  Updating the record field

            N := Make_Defining_Identifier (PN (P_Returns));
            Set_Correct_Parent_Unit_Name (N, Copy_Node (Args_Id));
            N := Make_Assignment_Statement
              (N,
               Cast_Variable_From_PolyORB_Type
               (PN (P_Returns), E));
            Append_Node_To_List (N, Client_Statements);

         end if;

         --  Handling parameters

         if not FEU.Is_Empty (P) then

            --  Aligning CDR position in Buffer in client and server parts

            if Contains_Out_Parameters (E) then
               N := Make_Subprogram_Call
                 (RE (RE_Align_Position),
                  Make_List_Id
                  (Make_Designator (PN (P_Buffer)),
                   Make_Designator (PN (P_Data_Alignment))));
               Append_Node_To_List (N, Client_Statements);
            end if;

            if Contains_In_Parameters (E) then
               N := Make_Subprogram_Call
                 (RE (RE_Align_Position),
                  Make_List_Id
                  (Make_Designator (PN (P_Buffer)),
                   Make_Designator (PN (P_Data_Alignment))));
               Append_Node_To_List (N, Server_Statements);
            end if;

            --  Skip the first parameter corresponding to 'Self'

            Parameter := First_Entity (P);
            while Present (Parameter) loop

               Rewinded_Type  := Get_Original_Type (Parameter);
               Parameter_Name := To_Ada_Name
                 (IDL_Name
                  (Identifier
                   (Declarator
                    (Parameter))));
               Parameter_Mode := FEN.Parameter_Mode (Parameter);

               --  The IN    parameters are unmarshalled by server
               --  The OUT   parameters are unmarshalled by client
               --  The INOUT parameters are unmarshalled by client and server

               --  Explaining comment

               Set_Str_To_Name_Buffer
                 ("Unmarshall Parameter : ");
               Get_Name_String_And_Append (Parameter_Name);
               Add_Str_To_Name_Buffer (" => ");
               Add_Str_To_Name_Buffer
                 (FEN.Node_Kind'Image
                  (FEN.Kind
                   (Get_Original_Type
                    (Parameter))));

               if Is_In (Parameter_Mode) then
                  N := Make_Ada_Comment (Name_Find);
                  Append_Node_To_List (N, Server_Statements);
               end if;
               if Is_Out (Parameter_Mode) then
                  N := Make_Ada_Comment (Name_Find);
                  Append_Node_To_List (N, Client_Statements);
               end if;

               --  Declaring the storage variable

               N := Storage_Variable_Declaration
                 (Parameter_Name, Parameter);
               Append_Node_To_List (N, Subp_Declarations);

               --  Unmarshalling the parameter and handling the error

               if Is_In (Parameter_Mode) then
                  N := Do_Unmarshall
                    (Parameter_Name,
                     Parameter,
                     PN (P_Buffer));
                  Append_Node_To_List (N, Server_Statements);
               end if;
               if Is_Out (Parameter_Mode) then
                  N := Do_Unmarshall
                    (Parameter_Name,
                     Parameter,
                     PN (P_Buffer));
                  Append_Node_To_List (N, Client_Statements);
               end if;

               --  Updating the record field

               if Is_In (Parameter_Mode) then
                  N := Make_Defining_Identifier (Parameter_Name);
                  Set_Correct_Parent_Unit_Name (N, Copy_Node (Args_Id));
                  N := Make_Assignment_Statement
                    (N,
                     Cast_Variable_From_PolyORB_Type
                     (Parameter_Name, Parameter));
                  Append_Node_To_List (N, Server_Statements);
               end if;
               if Is_Out (Parameter_Mode) then
                  N := Make_Defining_Identifier (Parameter_Name);
                  Set_Correct_Parent_Unit_Name (N, Copy_Node (Args_Id));
                  N := Make_Assignment_Statement
                    (N,
                     Cast_Variable_From_PolyORB_Type
                     (Parameter_Name, Parameter));
                  Append_Node_To_List (N, Client_Statements);
               end if;

               Parameter := Next_Entity (Parameter);
            end loop;
         end if;

         --  Building the case statement

         if BEU.Is_Empty (Client_Statements) then
            Append_Node_To_List (Make_Null_Statement, Client_Statements);
         end if;
         N := Make_Case_Statement_Alternative (Client_Case, Client_Statements);
         Append_Node_To_List (N, Case_Alternatives);

         if BEU.Is_Empty (Server_Statements) then
            Append_Node_To_List (Make_Null_Statement, Server_Statements);
         end if;
         N := Make_Case_Statement_Alternative (Server_Case, Server_Statements);
         Append_Node_To_List (N, Case_Alternatives);

         N := Make_Case_Statement
           (Make_Designator (PN (P_Role)), Case_Alternatives);
         Append_Node_To_List (N, Subp_Statements);

         --  Updating the argument list when needed

         Set_Str_To_Name_Buffer ("Update the argument list");
         N := Make_Ada_Comment (Name_Find);
         Append_Node_To_List (N, Subp_Statements);

         M := Make_Designator
           (Designator => PN (P_Args),
            Is_All     => True);
         N := Make_Attribute_Designator
           (RE (RE_Request_Args), A_Class);
         N := Make_Subprogram_Call
           (N,
            Make_List_Id
            (Copy_Node (Args_Id)));
         N := Make_Assignment_Statement (M, N);
         Append_Node_To_List (N, Subp_Statements);

         --  Building the subprogram implementation

         N := Make_Subprogram_Implementation
           (Specification => Subp_Spec,
            Declarations  => Subp_Declarations,
            Statements    => Subp_Statements);
         return N;
      end Unmarshaller_Body;

      -------------------
      -- Set_Args_Body --
      -------------------

      function Set_Args_Body (E : Node_Id) return Node_Id is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);
         Subp_Spec         : Node_Id;
         Subp_Statements   : constant List_Id := New_List (K_List_Id);
         Subp_Declarations : constant List_Id := New_List (K_List_Id);
         Aggregate_List    : constant List_Id := New_List (K_List_Id);
         Aggregate         : Node_Id;
         N                 : Node_Id;
      begin
         Subp_Spec := Set_Args_Node (BE_Node (Identifier (E)));

         --  Declarative Part

         --  Creating the Request Payload Constant :
         --  Req_Payload : constant PolyORB.Requests.Request_Payload_Access :=
         --    new PolyORB.Protocols.GIOP.Operation_Payload'
         --    (Args     => PolyORB.Requests.Request_Args'Class
         --     (Args.all)'Access,
         --     Unmarshaller => <Unmarshaller>'Access,
         --     Marshaller   => <Marshaller>'Access);

         --  1/
         --  (Args     => PolyORB.Requests.Request_Args'Class
         --   (Args.all)'Access,

         N := Make_Designator
           (Designator => PN (P_Args),
            Is_All     => True);
         N := Make_Subprogram_Call
           (Make_Attribute_Designator
            (RE (RE_Request_Args),
             A_Class),
            Make_List_Id (N));
         N := Make_Attribute_Designator (N, A_Access);

         Aggregate := Make_Component_Association
           (Selector_Name => Make_Designator (PN (P_Args)),
            Expression    => N);
         Append_Node_To_List (Aggregate, Aggregate_List);

         --  2/
         --  Unmarshaller => <Unmarshaller>'Access,

         N := Expand_Designator
           (Unmarshaller_Node
            (BE_Node
             (Identifier (E))));
         N := Make_Attribute_Designator (N, A_Access);
         Aggregate := Make_Component_Association
           (Selector_Name => RE (RE_Unmarshaller),
            Expression    => N);
         Append_Node_To_List (Aggregate, Aggregate_List);

         --  3/
         --  Marshaller => <Marshaller>'Access,

         N := Expand_Designator
           (Marshaller_Node
            (BE_Node
             (Identifier (E))));
         N := Make_Attribute_Designator (N, A_Access);
         Aggregate := Make_Component_Association
           (Selector_Name => RE (RE_Marshaller),
            Expression    => N);
         Append_Node_To_List (Aggregate, Aggregate_List);

         --  The object instanciation

         N := Make_Qualified_Expression
           (Subtype_Mark => RE (RE_Operation_Payload),
            Aggregate    => Make_Record_Aggregate (Aggregate_List));
         N := Make_Object_Instanciation (N);

         --  The constant declaration

         N := Make_Object_Declaration
           (Defining_Identifier => Make_Defining_Identifier
            (VN (V_Req_Payload)),
            Constant_Present    => True,
            Object_Definition   => RE (RE_Request_Payload_Access),
            Expression          => N);
         Append_Node_To_List (N, Subp_Declarations);

         --  Statements

         --  Setting the request payload

         N := Make_Designator
           (Designator => PN (P_Payload),
            Parent     => PN (P_Request));
         N := Make_Assignment_Statement
           (N, Make_Designator (VN (V_Req_Payload)));
         Append_Node_To_List (N, Subp_Statements);

         --  Creating the subprogram implementation

         N := Make_Subprogram_Implementation
           (Specification => Subp_Spec,
            Declarations  => Subp_Declarations,
            Statements    => Subp_Statements);

         return N;
      end Set_Args_Body;

      -----------------------
      -- Get_Original_Type --
      -----------------------

      function Get_Original_Type
        (Parameter   : Node_Id;
         Declarators : List_Id := No_List)
        return Node_Id
      is
         Original_Type : Node_Id;
         Param_Type    : Node_Id;
         N             : Node_Id;
      begin
         Param_Type := Type_Spec (Parameter);

         if FEN.Kind (Param_Type) = K_Scoped_Name then

            --  A scoped name type designates either a declarator or an object

            N := Reference (Param_Type);
            if FEN.Kind (N) = K_Simple_Declarator or else
              FEN.Kind (N) = K_Complex_Declarator
            then
               Original_Type := Get_Original_Type
                 (Declaration (N), Declarators);
            else
               return N;
            end if;

         elsif FEN.Kind (Param_Type) = K_Simple_Declarator then

            --  The complex declarators are not resolved at this stade

            Original_Type := Get_Original_Type
              (Declaration (Param_Type), Declarators);
         else
            if FEN.Kind (Parameter) = K_Type_Declaration and then
              Declarators /= No_List and then
              FEU.Is_Empty (Declarators)
            then
               FEU.Append_Node_To_List
                 (First_Entity (FEN.Declarators (Parameter)),
                  Declarators);
            end if;
            Original_Type := Param_Type;
         end if;

         return Original_Type;
      end Get_Original_Type;

      ----------------------------------
      -- Storage_Variable_Declaration --
      ----------------------------------

      function Storage_Variable_Declaration
        (Var_Name : Name_Id; Var_Node : Node_Id)
        return Node_Id
      is
         N           : Node_Id;
         Var_Type    : Node_Id;
         Declarators : constant List_Id := FEU.New_List
           (K_List_Id, Locations.No_Location);
      begin

         Var_Type := Get_Original_Type (Var_Node, Declarators);

         case FEN.Kind (Var_Type) is

            when K_Long =>
               N := Make_Object_Declaration
                 (Defining_Identifier => Make_Defining_Identifier (Var_Name),
                  Object_Definition   => RE (RE_Long_1));

            when K_Short =>
               N := Make_Object_Declaration
                 (Defining_Identifier => Make_Defining_Identifier (Var_Name),
                  Object_Definition   => RE (RE_Short_1));

            when K_String =>
               N := Make_Object_Declaration
                 (Defining_Identifier => Make_Defining_Identifier (Var_Name),
                  Object_Definition   => RE (RE_String_1));

            when K_Sequence_Type =>
               declare
                  Declarator       : Node_Id;
                  Seq_Package_Node : Node_Id;
                  Seq_Exp          : Node_Id;
               begin

                  --  Getting the instanciated package node

                  Declarator := First_Entity (Declarators);
                  Seq_Package_Node := Defining_Identifier
                    (Stub_Package_Node
                     (BE_Ada_Instanciations
                      (BE_Node
                       (Identifier
                        (Declarator)))));

                  --  Sequence type

                  N := Make_Designator (TN (T_Sequence));
                  Set_Correct_Parent_Unit_Name (N, Seq_Package_Node);

                  --  null sequence

                  Seq_Exp := Make_Designator (PN (P_Null_Sequence));
                  Set_Correct_Parent_Unit_Name (Seq_Exp, Seq_Package_Node);

                  --  Variable declaration

                  N := Make_Object_Declaration
                    (Defining_Identifier => Make_Defining_Identifier
                     (Var_Name),
                     Object_Definition   => N,
                     Expression          => Seq_Exp);
               end;

            when K_Unsigned_Long =>
               N := Make_Object_Declaration
                 (Defining_Identifier => Make_Defining_Identifier (Var_Name),
                  Object_Definition   => RE (RE_Unsigned_Long_1));

            when others =>
               Get_Name_String (Var_Name);
               Add_Str_To_Name_Buffer (" : ");
               Add_Str_To_Name_Buffer
                 (FEN.Node_Kind'Image
                  (FEN.Kind
                   (Var_Type)));
               N := Make_Ada_Comment (Name_Find);
         end case;

         return N;
      end Storage_Variable_Declaration;

      -------------------------------------
      -- Cast_Variable_From_PolyORB_Type --
      -------------------------------------

      function Cast_Variable_From_PolyORB_Type
        (Var_Name : Name_Id; Var_Node : Node_Id)
        return Node_Id
      is
         N           : Node_Id;
         Var_Type    : Node_Id;
         Declarators : constant List_Id := FEU.New_List
           (K_List_Id, Locations.No_Location);
      begin
         N := Make_Designator (Var_Name);

         Var_Type := Get_Original_Type (Var_Node, Declarators);

         case FEN.Kind (Var_Type) is

            when K_String =>
               begin
                  N := Make_Subprogram_Call
                    (RE (RE_To_Standard_String_1),
                     Make_List_Id (N));
                  N := Make_Subprogram_Call
                    (RE (RE_To_CORBA_String),
                     Make_List_Id (N));
                  if FEN.Kind (Type_Spec (Var_Node)) /= K_String then
                     N := Make_Subprogram_Call
                    (Map_Designator (Type_Spec (Var_Node)),
                     Make_List_Id (N));
                  end if;
               end;

            when K_Long
              | K_Sequence_Type
              | K_Short
              | K_Unsigned_Long =>
               declare
                  Var_Type : constant Node_Id := Map_Designator
                    (Type_Spec (Var_Node));
               begin
                  N := Make_Subprogram_Call
                    (Var_Type,
                     Make_List_Id (N));
               end;

            when others =>
               null;
         end case;

         return N;
      end Cast_Variable_From_PolyORB_Type;

      -----------------------------------
      -- Cast_Variable_To_PolyORB_Type --
      -----------------------------------

      function Cast_Variable_To_PolyORB_Type
        (Var_Node : Node_Id; Type_Dcl : Node_Id)
        return Node_Id
      is
         N : Node_Id;
         Var_Type    : Node_Id;
         Declarators : constant List_Id := FEU.New_List
           (K_List_Id, Locations.No_Location);
      begin
         N := Var_Node;

         Var_Type := Get_Original_Type (Type_Dcl, Declarators);

         case FEN.Kind (Var_Type) is

            when K_Long =>
               begin
                  N := Make_Subprogram_Call
                    (RE (RE_Long_1), Make_List_Id (N));
               end;

            when K_Short =>
               begin
                  N := Make_Subprogram_Call
                    (RE (RE_Short_1), Make_List_Id (N));
               end;

            when K_String =>
               begin
                  if FEN.Kind (Type_Spec (Type_Dcl)) /= K_String then
                     N := Make_Subprogram_Call
                       (RE (RE_String_0),
                        Make_List_Id (N));
                  end if;

                  N := Make_Subprogram_Call
                    (RE (RE_To_Standard_String),
                     Make_List_Id (N));
                  N := Make_Subprogram_Call
                    (RE (RE_To_PolyORB_String),
                     Make_List_Id (N));
               end;

            when K_Sequence_Type =>
               declare
                  Declarator       : Node_Id;
                  Seq_Package_Node : Node_Id;
                  Seq_Type         : Node_Id;
               begin

                  --  Getting the instanciated package node

                  Declarator := First_Entity (Declarators);
                  Seq_Package_Node := Defining_Identifier
                    (Stub_Package_Node
                     (BE_Ada_Instanciations
                      (BE_Node
                       (Identifier
                        (Declarator)))));

                  --  Sequence type

                  Seq_Type := Make_Designator (TN (T_Sequence));
                  Set_Correct_Parent_Unit_Name (Seq_Type, Seq_Package_Node);

                  N := Make_Subprogram_Call
                    (Seq_Type,
                     Make_List_Id (N));
               end;

            when K_Unsigned_Long =>
               begin
                  N := Make_Subprogram_Call
                    (RE (RE_Unsigned_Long_1),
                     Make_List_Id (N));
               end;

            when others =>
               null;
         end case;

         return N;
      end Cast_Variable_To_PolyORB_Type;

      -------------------
      -- Do_Unmarshall --
      -------------------

      function Do_Unmarshall
        (Var_Name : Name_Id;
         Var_Type : Node_Id;
         Buff     : Name_Id)
        return Node_Id
      is
         Block_Dcl      : constant List_Id := New_List (K_List_Id);
         Block_St       : constant List_Id := New_List (K_List_Id);
         N              : Node_Id;
         Type_Spec_Node : Node_Id;
         Declarators    : constant List_Id := FEU.New_List
           (K_List_Id, Locations.No_Location);
      begin
         --  Getting the original type

         Type_Spec_Node := Get_Original_Type (Var_Type, Declarators);

         case FEN.Kind (Type_Spec_Node) is

            when K_Boolean
              | K_Double
              | K_Float
              | K_Long
              | K_Long_Double
              | K_Long_Long
              | K_Octet
              | K_Short
              | K_Unsigned_Long
              | K_Unsigned_Long_Long
              | K_Unsigned_Short =>

               begin
                  N := Make_Subprogram_Call
                    (RE (RE_Unmarshall_2),
                     Make_List_Id
                     (Make_Designator (Buff)));
                  N := Make_Assignment_Statement
                    (Make_Designator (Var_Name), N);
                  Append_Node_To_List (N, Block_St);
               end;

            when K_Char
              | K_String
              | K_Wide_Char
              | K_Wide_String =>
               declare
                  Profile : constant List_Id := New_List (K_List_Id);
               begin
                  N := Make_Designator (PN (P_Representation));
                  Append_Node_To_List (N, Profile);

                  N := Make_Designator (Buff);
                  Append_Node_To_List (N, Profile);

                  N := Make_Designator (Var_Name);
                  Append_Node_To_List (N, Profile);

                  N := Make_Designator (PN (P_Error));
                  Append_Node_To_List (N, Profile);

                  N := Make_Subprogram_Call (RE (RE_Unmarshall_1), Profile);
                  Append_Node_To_List (N, Block_St);

                  --  Handling the error

                  N := Make_Subprogram_Call
                    (RE (RE_Found),
                     Make_List_Id (Make_Designator (PN (P_Error))));
                  N := Make_If_Statement
                    (Condition       => N,
                     Then_Statements => Make_List_Id
                     (Make_Return_Statement (No_Node)));
                  Append_Node_To_List (N, Block_St);
               end;

            when K_Sequence_Type =>
               declare
                  Declarator       : Node_Id;
                  Seq_Package_Node : Node_Id;
                  Seq_Node         : Node_Id;
                  Index_Node       : Node_Id;
                  Range_Constraint : Node_Id;
                  For_Statements   : constant List_Id := New_List (K_List_Id);
               begin
                  if FEU.Is_Empty (Declarators) then
                     raise Program_Error;
                  end if;

                  --  Getting the instanciated package node

                  Declarator := First_Entity (Declarators);
                  Seq_Package_Node := Defining_Identifier
                    (Stub_Package_Node
                     (BE_Ada_Instanciations
                      (BE_Node
                       (Identifier
                        (Declarator)))));

                  --  Sequence variable

                  Seq_Node := Make_Defining_Identifier (Var_Name);

                  --  Getting the sequence length

                  N := Make_Object_Declaration
                    (Defining_Identifier => Make_Defining_Identifier
                     (VN (V_Seq_Len)),
                     Object_Definition   => RE (RE_Unsigned_Long_1));
                  Append_Node_To_List (N, Block_Dcl);

                  --  Unmarshalling the sequence length

                  N := Make_Subprogram_Call
                    (RE (RE_Unmarshall_2),
                     Make_List_Id
                     (Make_Designator (Buff)));
                  N := Make_Assignment_Statement
                    (Make_Designator (VN (V_Seq_Len)), N);
                  Append_Node_To_List (N, Block_St);

                  --  Marshalling the sequence elements

                  Index_Node := Make_Defining_Identifier (VN (V_Index));

                  --    Creating the range constraint

                  Range_Constraint := New_Node (K_Range_Constraint);
                  Set_First
                    (Range_Constraint,
                     Make_Literal (Int1_Val));
                  Set_Last
                    (Range_Constraint,
                     Make_Defining_Identifier (VN (V_Seq_Len)));

                  --    Declaring the element variable

                  N := Storage_Variable_Declaration
                    (VN (V_Seq_Element), Type_Spec_Node);
                  Append_Node_To_List (N, Block_Dcl);

                  --    Unmarshalling the sequence element

                  N := Do_Unmarshall
                    (Var_Name => VN (V_Seq_Element),
                     Var_Type => Type_Spec_Node,
                     Buff     => Buff);
                  Append_Node_To_List (N, For_Statements);

                  --    Appending the sequence element

                  N := Make_Designator (SN (S_Append));
                  Set_Correct_Parent_Unit_Name (N, Seq_Package_Node);

                  N := Make_Subprogram_Call
                    (N,
                     Make_List_Id
                     (Seq_Node,
                      Cast_Variable_From_PolyORB_Type
                      (VN (V_Seq_Element), Type_Spec_Node)));

                  Append_Node_To_List (N, For_Statements);

                  --  Building the loop

                  N := Make_For_Statement
                    (Index_Node,
                     Range_Constraint,
                     For_Statements);
                  Append_Node_To_List (N, Block_St);
               end;

            when others =>
               Append_Node_To_List (Make_Null_Statement, Block_St);
         end case;

         N := Make_Block_Statement
           (Declarative_Part => Block_Dcl,
            Statements       => Block_St);
         return N;
      end Do_Unmarshall;

      -----------------
      -- Do_Marshall --
      -----------------

      function Do_Marshall
        (Var_Node : Node_Id;
         Var_Type : Node_Id;
         Buff     : Name_Id)
        return Node_Id
      is
         Block_Dcl : constant List_Id := New_List (K_List_Id);
         Block_St  : constant List_Id := New_List (K_List_Id);
         N         : Node_Id;
         Type_Spec_Node : Node_Id;
         Declarators    : constant List_Id := FEU.New_List
           (K_List_Id, Locations.No_Location);
      begin
         --  Getting the original type
         Type_Spec_Node := Get_Original_Type (Var_Type, Declarators);

         case FEN.Kind (Type_Spec_Node) is

            when K_Boolean
              | K_Double
              | K_Float
              | K_Long
              | K_Long_Double
              | K_Long_Long
              | K_Octet
              | K_Short
              | K_Unsigned_Long
              | K_Unsigned_Long_Long
              | K_Unsigned_Short =>

               N := Make_Subprogram_Call
                 (RE (RE_Marshall_2),
                  Make_List_Id
                  (Make_Designator (Buff),
                   Cast_Variable_To_PolyORB_Type (Var_Node, Var_Type)));
               Append_Node_To_List (N, Block_St);

            when K_Char
              | K_String
              | K_Wide_Char
              | K_Wide_String =>
               declare
                  Profile : constant List_Id := New_List (K_List_Id);
               begin
                  N := Make_Designator (PN (P_Representation));
                  Append_Node_To_List (N, Profile);

                  N := Make_Designator (Buff);
                  Append_Node_To_List (N, Profile);

                  Append_Node_To_List
                    (Cast_Variable_To_PolyORB_Type (Var_Node, Var_Type),
                     Profile);

                  N := Make_Designator (PN (P_Error));
                  Append_Node_To_List (N, Profile);

                  N := Make_Subprogram_Call (RE (RE_Marshall_1), Profile);
                  Append_Node_To_List (N, Block_St);

                  --  Handling the error

                  N := Make_Subprogram_Call
                    (RE (RE_Found),
                     Make_List_Id (Make_Designator (PN (P_Error))));
                  N := Make_If_Statement
                    (Condition       => N,
                     Then_Statements => Make_List_Id
                     (Make_Return_Statement (No_Node)));
                  Append_Node_To_List (N, Block_St);
               end;

            when K_Sequence_Type =>
               declare
                  Declarator       : Node_Id;
                  Seq_Package_Node : Node_Id;
                  Seq_Element      : Node_Id;
                  Index_Node       : Node_Id;
                  Range_Constraint : Node_Id;
                  For_Statements   : constant List_Id := New_List (K_List_Id);
               begin
                  if FEU.Is_Empty (Declarators) then
                     raise Program_Error;
                  end if;

                  --  Getting the instanciated package node

                  Declarator := First_Entity (Declarators);
                  Seq_Package_Node := Defining_Identifier
                    (Stub_Package_Node
                     (BE_Ada_Instanciations
                      (BE_Node
                       (Identifier
                        (Declarator)))));

                  --  Getting the sequence length

                  N := Make_Object_Declaration
                    (Defining_Identifier => Make_Defining_Identifier
                     (VN (V_Seq_Len)),
                     Object_Definition   => RE (RE_Unsigned_Long_1));
                  Append_Node_To_List (N, Block_Dcl);

                  N := Make_Designator (SN (S_Length));
                  Set_Correct_Parent_Unit_Name (N, Seq_Package_Node);

                  N := Make_Subprogram_Call
                    (N,
                     Make_List_Id
                     (Cast_Variable_To_PolyORB_Type (Var_Node, Var_Type)));
                  N := Make_Subprogram_Call
                    (RE (RE_Unsigned_Long_1),
                     Make_List_Id (N));
                  N := Make_Assignment_Statement
                    (Make_Defining_Identifier (VN (V_Seq_Len)), N);
                  Append_Node_To_List (N, Block_St);

                  --  Marshalling the sequence length

                  N := Make_Subprogram_Call
                    (RE (RE_Marshall_2),
                     Make_List_Id
                     (Make_Designator (Buff),
                      Make_Defining_Identifier (VN (V_Seq_Len))));
                  Append_Node_To_List (N, Block_St);

                  --  Marshalling the sequence elements

                  Index_Node := Make_Defining_Identifier (VN (V_Index));

                  --    Creating the range constraint

                  Range_Constraint := New_Node (K_Range_Constraint);
                  Set_First
                    (Range_Constraint,
                     Make_Literal (Int1_Val));
                  Set_Last
                    (Range_Constraint,
                     Make_Defining_Identifier (VN (V_Seq_Len)));

                  --    Getting the sequence element

                  N := Make_Designator (SN (S_Element_Of));
                  Set_Correct_Parent_Unit_Name (N, Seq_Package_Node);

                  Seq_Element := Make_Subprogram_Call
                    (N,
                     Make_List_Id
                     (Cast_Variable_To_PolyORB_Type (Var_Node, Var_Type),
                      Make_Subprogram_Call
                      (RE (RE_Positive),
                       Make_List_Id (Index_Node))));

                  --    Marshalling the sequence element

                  N := Do_Marshall
                    (Var_Node => Seq_Element,
                     Var_Type => Type_Spec_Node,
                     Buff     => Buff);
                  Append_Node_To_List (N, For_Statements);

                  --    Building the loop

                  N := Make_For_Statement
                    (Index_Node,
                     Range_Constraint,
                     For_Statements);
                  Append_Node_To_List (N, Block_St);
               end;

            when others =>
               Append_Node_To_List (Make_Null_Statement, Block_St);
         end case;

         N := Make_Block_Statement
           (Declarative_Part => Block_Dcl,
            Statements       => Block_St);
         return N;
      end Do_Marshall;

      -----------
      -- Is_In --
      -----------

      function Is_In (Par_Mode : Mode_Id) return Boolean is
      begin
         return Par_Mode = Mode_In or else Par_Mode = Mode_Inout;
      end Is_In;

      ------------
      -- Is_Out --
      ------------

      function Is_Out (Par_Mode : Mode_Id) return Boolean is
      begin
         return Par_Mode = Mode_Out or else Par_Mode = Mode_Inout;
      end Is_Out;

      ----------------------------
      -- Contains_In_Parameters --
      ----------------------------

      function Contains_In_Parameters (E : Node_Id) return Boolean is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);

         Parameter : Node_Id;
         Result    : Boolean := False;
      begin
         Parameter := First_Entity (Parameters (E));
         while Present (Parameter) loop
            if Is_In (FEN.Parameter_Mode (Parameter)) then
               Result := True;
               exit;
            end if;
            Parameter := Next_Entity (Parameter);
         end loop;
         return Result;
      end Contains_In_Parameters;

      -----------------------------
      -- Contains_Out_Parameters --
      -----------------------------

      function Contains_Out_Parameters (E : Node_Id) return Boolean is
         pragma Assert (FEN.Kind (E) = K_Operation_Declaration);

         Parameter : Node_Id;
         Result    : Boolean := False;
      begin
         Parameter := First_Entity (Parameters (E));
         while Present (Parameter) loop
            if Is_Out (FEN.Parameter_Mode (Parameter)) then
               Result := True;
               exit;
            end if;
            Parameter := Next_Entity (Parameter);
         end loop;
         return Result;
      end Contains_Out_Parameters;

      -----------
      -- Visit --
      -----------

      procedure Visit (E : Node_Id) is
      begin
         case FEN.Kind (E) is

            when K_Attribute_Declaration =>
               Visit_Attribute_Declaration (E);

            when K_Interface_Declaration =>
               Visit_Interface_Declaration (E);

            when K_Module =>
               Visit_Module (E);

            when K_Operation_Declaration =>
               Visit_Operation_Declaration (E);

            when K_Specification =>
               Visit_Specification (E);

            when others =>
               null;

         end case;
      end Visit;

      ---------------------------------
      -- Visit_Attribute_Declaration --
      ---------------------------------

      procedure Visit_Attribute_Declaration (E : Node_Id) is
         N    : Node_Id;
         D    : Node_Id;
      begin
         Set_CDR_Body;

         D := First_Entity (Declarators (E));
         while Present (D) loop
            Set_Str_To_Name_Buffer
              ("Attribute : ");
            Get_Name_String_And_Append (IDL_Name (Identifier (D)));
            N := Make_Ada_Comment (Name_Find);
            Append_Node_To_List (N, Statements (Current_Package));

            D := Next_Entity (D);
         end loop;
      end Visit_Attribute_Declaration;

      ---------------------------------
      -- Visit_Interface_Declaration --
      ---------------------------------

      procedure Visit_Interface_Declaration (E : Node_Id) is
         N : Node_Id;
      begin
         --  No CDR package is generated for a local interface

         if FEN.Is_Local_Interface (E) then
            return;
         end if;

         N := BEN.Parent (Type_Def_Node (BE_Node (Identifier (E))));
         Push_Entity (BEN.IDL_Unit (Package_Declaration (N)));
         Set_CDR_Body;

         N := First_Entity (Interface_Body (E));
         while Present (N) loop
            Visit (N);
            N := Next_Entity (N);
         end loop;

         Pop_Entity;
      end Visit_Interface_Declaration;

      ------------------
      -- Visit_Module --
      ------------------

      procedure Visit_Module (E : Node_Id) is
         D : Node_Id;
      begin
         if not Map_Particular_CORBA_Parts (E, PK_CDR_Body) then
            Push_Entity (Stub_Node (BE_Node (Identifier (E))));
            D := First_Entity (Definitions (E));
            while Present (D) loop
               Visit (D);
               D := Next_Entity (D);
            end loop;
            Pop_Entity;
         end if;
      end  Visit_Module;

      ---------------------------------
      -- Visit_Operation_Declaration --
      ---------------------------------

      procedure Visit_Operation_Declaration (E : Node_Id) is
         N     : Node_Id;
      begin
         Set_CDR_Body;

         --  Explaining comment

         Set_Str_To_Name_Buffer
           ("Operation : ");
         Get_Name_String_And_Append (IDL_Name (Identifier (E)));
         N := Make_Ada_Comment (Name_Find);
         Append_Node_To_List (N, Statements (Current_Package));

         --  Generating the 'Operation_Name'_Unmarshaller Body

         N := Unmarshaller_Body (E);
         Append_Node_To_List (N, Statements (Current_Package));

         --  Generating the 'Operation_Name'_Marshaller Body

         N := Marshaller_Body (E);
         Append_Node_To_List (N, Statements (Current_Package));

         --  Generating the 'Operation_Name'_Set_Args Body

         N := Set_Args_Body (E);
         Append_Node_To_List (N, Statements (Current_Package));
      end Visit_Operation_Declaration;

      -------------------------
      -- Visit_Specification --
      -------------------------

      procedure Visit_Specification (E : Node_Id) is
         Definition : Node_Id;
      begin
         Push_Entity (Stub_Node (BE_Node (Identifier (E))));
         Definition := First_Entity (Definitions (E));
         while Present (Definition) loop
            Visit (Definition);
            Definition := Next_Entity (Definition);
         end loop;
         Pop_Entity;
      end Visit_Specification;
   end Package_Body;

end Backend.BE_Ada.CDRs;
