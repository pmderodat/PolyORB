--  with Namet;  use Namet;
with Values; use Values;

with Frontend.Nodes;  use Frontend.Nodes;

with Backend.BE_Ada.Expand;      use Backend.BE_Ada.Expand;
with Backend.BE_Ada.IDL_To_Ada;  use Backend.BE_Ada.IDL_To_Ada;
with Backend.BE_Ada.Nodes;       use Backend.BE_Ada.Nodes;
with Backend.BE_Ada.Nutils;      use Backend.BE_Ada.Nutils;
with Backend.BE_Ada.Runtime;     use Backend.BE_Ada.Runtime;
--  with Backend.BE_Ada.Debug;     use Backend.BE_Ada.Debug;

package body Backend.BE_Ada.Skels is
   package FEN renames Frontend.Nodes;
   package BEN renames Backend.BE_Ada.Nodes;

   package body Package_Spec is

      procedure Visit_Interface_Declaration (E : Node_Id);
      procedure Visit_Module (E : Node_Id);
      procedure Visit_Specification (E : Node_Id);

      -----------
      -- Visit --
      -----------

      procedure Visit (E : Node_Id) is
      begin
         case FEN.Kind (E) is
            when K_Interface_Declaration =>
               Visit_Interface_Declaration (E);

            when K_Module =>
               Visit_Module (E);

            when K_Specification =>
               Visit_Specification (E);

            when others =>
               null;
         end case;
      end Visit;

      ---------------------------------
      -- Visit_Interface_Declaration --
      ---------------------------------

      procedure Visit_Interface_Declaration (E : Node_Id) is
         N : Node_Id;
      begin
         N := BEN.Parent (Stub_Node (BE_Node (Identifier (E))));
         Push_Entity (BEN.IDL_Unit (Package_Declaration (N)));
         Set_Skeleton_Spec;
         N := Make_Subprogram_Call
           (Make_Defining_Identifier (GN (Pragma_Elaborate_Body)),
            No_List);
         N := Make_Pragma_Statement (N);
         Append_Node_To_List (N, Visible_Part (Current_Package));
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
         Push_Entity (Stub_Node (BE_Node (Identifier (E))));

         D := First_Entity (Definitions (E));
         while Present (D) loop
            Visit (D);
            D := Next_Entity (D);
         end loop;
         Pop_Entity;
      end Visit_Module;

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

      Invoke_Elsif_Statements : List_Id;

      function Gen_Invoke_Part (S : Node_Id) return Node_Id;
      procedure Invoke_Declaration (L : List_Id);
      function Invoke_Spec return Node_Id;

      procedure Visit_Attribute_Declaration (E : Node_Id);
      procedure Visit_Interface_Declaration (E : Node_Id);
      procedure Visit_Module (E : Node_Id);
      procedure Visit_Specification (E : Node_Id);

      ---------------------
      -- Gen_Invoke_Part --
      ---------------------

      function Gen_Invoke_Part (S : Node_Id) return Node_Id is
         C                : Node_Id;
         Count            : Natural;
         N                : Node_Id;
         Declarative_Part : constant List_Id := New_List (K_List_Id);
         Statements       : constant List_Id := New_List (K_List_Id);
         Param            : Node_Id;
         Param_Name       : Name_Id;
         New_Name         : Name_Id;
         P                : List_Id;
      begin
         Count := Length (Parameter_Profile (S));

         N := Make_Subprogram_Call
           (RE (RE_Arguments),
            Make_List_Id
            (Make_Defining_Identifier (VN (V_Argument_List))));
         Append_Node_To_List (N, Statements);

         if Count > 1 then
            Param := First_Node (Parameter_Profile (S));
            Param := Next_Node (Param);
            loop
               P := Make_List_Id (Make_Designator (VN (V_Argument_List)));
               Param_Name := BEN.Name (Defining_Identifier (Param));
               N :=  Make_Object_Declaration
                 (Defining_Identifier =>
                    Make_Defining_Identifier (Param_Name),
                  Object_Definition   =>
                    Copy_Designator (Parameter_Type (Param)));
               Append_Node_To_List (N, Declarative_Part);
               C := Make_Subprogram_Call
                 (Defining_Identifier   => RE (RE_To_CORBA_String),
                  Actual_Parameter_Part =>
                    Make_List_Id (Make_Literal
                                  (New_String_Value (Param_Name, False))));
               New_Name := Add_Prefix_To_Name ("Arg_Name_U_", Param_Name);
               Append_Node_To_List (Make_Designator (New_Name), P);
               N := Make_Object_Declaration
                 (Defining_Identifier => Make_Defining_Identifier (New_Name),
                  Constant_Present => False,
                  Object_Definition => RE (RE_Identifier_0),
                  Expression => C);
               Append_Node_To_List (N, Declarative_Part);

               if Is_Base_Type (BEN.FE_Node (Parameter_Type (Param))) then
                  C := Base_Type_TC
                    (FEN.Kind (BEN.FE_Node (Parameter_Type (Param))));
               else
                     C := Identifier (FE_Node (Parameter_Type (Param)));
                     C := Helper_Node
                       (BE_Node
                        (Identifier (Reference (Corresponding_Entity (C)))));
                     C := Expand_Designator (Next_Node (Next_Node (C)));
               end if;

               C :=  Make_Subprogram_Call
                 (Defining_Identifier   => RE (RE_Get_Empty_Any_0),
                  Actual_Parameter_Part =>
                    Make_List_Id (C));
               New_Name := Add_Prefix_To_Name ("Argument_U_", Param_Name);
               Append_Node_To_List (Make_Designator (New_Name), P);
               N := Make_Object_Declaration
                 (Defining_Identifier => Make_Defining_Identifier (New_Name),
                  Constant_Present => False,
                  Object_Definition => RE (RE_Any),
                  Expression => C);
               Append_Node_To_List (N, Declarative_Part);

               if BEN.Parameter_Mode (Param) = Mode_Out then
                  N := RE (RE_ARG_IN_0);
               elsif BEN.Parameter_Mode (Param) = Mode_In then
                  N := RE (RE_ARG_OUT_0);
               else
                  N := RE (RE_ARG_INOUT_0);
               end if;

               Append_Node_To_List (N, P);
               N := Make_Subprogram_Call
                 (RE (RE_Add_Item_0),
                  P);
               Append_Node_To_List (N, Statements);
               Param := Next_Node (Param);
               exit when No (Param);
            end loop;
         end if;

         --  Convert from their Any

         if Count > 1 then
            Param := First_Node (Parameter_Profile (S));
            Param := Next_Node (Param);
            loop
               if  BEN.Parameter_Mode (Param) = Mode_In then
                  Param_Name := BEN.Name (Defining_Identifier (Param));
                  New_Name := Add_Prefix_To_Name ("Argument_U_", Param_Name);

                  if Is_Base_Type (BEN.FE_Node (Parameter_Type (Param))) then
                     C := RE (RE_From_Any_0);
                  else
                     C := Identifier (FE_Node (Parameter_Type (Param)));
                     C := Helper_Node
                       (BE_Node
                        (Identifier (Reference (Corresponding_Entity (C)))));
                     C := Expand_Designator (C);
                  end if;

                  N := Make_Assignment_Statement
                    (Make_Defining_Identifier (Param_Name),
                     Make_Subprogram_Call
                     (C, Make_List_Id (Make_Designator (New_Name))));
                  Append_Node_To_List (N, Statements);
               end if;

               Param := Next_Node (Param);
               exit when No (Param);
            end loop;
         end if;

         --  Call Implementation

         if No (N) then
            raise Program_Error;
         end if;

         if Present (Return_Type (S)) then
            N := Make_Object_Declaration
              (Defining_Identifier =>
                 Make_Defining_Identifier (VN (V_Result)),
               Object_Definition =>
                 Copy_Designator (Return_Type (S)));
            Append_Node_To_List (N, Declarative_Part);
         else
            null;
         end if;

         C := Make_Expression
           (Make_Defining_Identifier (VN (V_Operation)),
            Op_Equal,
            Make_Literal
            (New_String_Value
             (Add_Suffix_To_Name
              ("_", BEN.Name (Defining_Identifier (S))), False)));
         N := Make_Block_Statement
           (Declarative_Part => Declarative_Part,
            Statements       => Statements);
         N := Make_Elsif_Statement
           (C, Make_List_Id (N));
         return N;
      end Gen_Invoke_Part;

      ------------------------
      -- Invoke_Declaration --
      ------------------------

      procedure Invoke_Declaration (L : List_Id) is
         N : Node_Id;
      begin
         N := Make_Designator
           (Designator => PN (P_Request),
            Is_All     => True);
         N := Make_Subprogram_Call
           (RE (RE_Operation),
            Make_List_Id (N));
         N := Make_Subprogram_Call
           (RE (RE_To_Standard_String),
            Make_List_Id (N));
         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (VN (V_Operation)),
            Constant_Present    => True,
            Object_Definition   => RE (RE_String_0),
            Expression          => N);
         Append_Node_To_List (N, L);
         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (VN (V_Argument_List)),
            Object_Definition   => RE (RE_Ref_3));
         Append_Node_To_List (N, L);
      end Invoke_Declaration;

      -----------------
      -- Invoke_Spec --
      -----------------

      function Invoke_Spec return Node_Id is
         N       : Node_Id;
         Param   : Node_Id;
         Profile : List_Id;

      begin
         Profile := New_List (K_List_Id);
         Param   := Make_Parameter_Specification
           (Make_Defining_Identifier (PN (P_Self)),
            RE (RE_Servant));
         Append_Node_To_List (Param, Profile);
         Param := Make_Parameter_Specification
           (Make_Defining_Identifier (PN (P_Request)),
            RE (RE_Object_Ptr));
         Append_Node_To_List (Param, Profile);
         N := Make_Subprogram_Specification
           (Make_Defining_Identifier (SN (S_Invoke)),
            Profile,
            No_Node);
         return N;
      end Invoke_Spec;

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
         N          : Node_Id;
         A          : Node_Id;

      begin
         A := First_Entity (Declarators (E));
         while Present (A) loop
            N := Stub_Node (BE_Node (Identifier (A)));

            if No (N) then
               raise Program_Error;
            end if;
            N := Gen_Invoke_Part (N);
            Append_Node_To_List (N, Invoke_Elsif_Statements);

            if not Is_Readonly (E) then
               N := Next_Node (Stub_Node (BE_Node (Identifier (A))));
               N := Gen_Invoke_Part (N);
               Append_Node_To_List (N, Invoke_Elsif_Statements);
            end if;

            A := Next_Entity (A);
         end loop;
      end Visit_Attribute_Declaration;

      ---------------------------------
      -- Visit_Interface_Declaration --
      ---------------------------------

      procedure Visit_Interface_Declaration (E : Node_Id) is
         N                 : Node_Id;
         Spec              : Node_Id;
         D                 : constant List_Id := New_List (K_List_Id);
         C                 : Node_Id;
         Then_Statements   : constant List_Id := New_List (K_List_Id);
         Else_Statements   : constant List_Id := New_List (K_List_Id);
         Invoke_Statements : constant List_Id := New_List (K_List_Id);

      begin
         N := BEN.Parent (Stub_Node (BE_Node (Identifier (E))));
         Push_Entity (BEN.IDL_Unit (Package_Declaration (N)));
         Set_Skeleton_Body;
         Invoke_Elsif_Statements := New_List (K_List_Id);

         N := First_Entity (Interface_Body (E));
         while Present (N) loop
            Visit (N);
            N := Next_Entity (N);
         end loop;

         Spec := Invoke_Spec;
         Invoke_Declaration (D);
         N := Make_Subprogram_Call
           (RE (RE_Create_List),
            Make_List_Id
            (Make_Literal (Int0_Val),
             Make_Defining_Identifier (VN (V_Argument_List))));
         Append_Node_To_List (N, Invoke_Statements);
         C := Make_Expression
           (Make_Defining_Identifier (VN (V_Operation)),
            Op_Equal,
            Make_Literal
            (New_String_Value
             (Add_Prefix_To_Name ("_", SN (S_Is_A)), False)));
         N := Make_If_Statement
           (C,
            Then_Statements,
            Invoke_Elsif_Statements,
            Else_Statements);
         Append_Node_To_List (N, Invoke_Statements);
         N := Make_Subprogram_Implementation
           (Spec, D, Invoke_Statements);
         Append_Node_To_List (N, Statements (Current_Package));
         Pop_Entity;
      end Visit_Interface_Declaration;

      ------------------
      -- Visit_Module --
      ------------------

      procedure Visit_Module (E : Node_Id) is
         D : Node_Id;
      begin
         Push_Entity (Stub_Node (BE_Node (Identifier (E))));
         D := First_Entity (Definitions (E));
         while Present (D) loop
            Visit (D);
            D := Next_Entity (D);
         end loop;
         Pop_Entity;
      end Visit_Module;

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
end Backend.BE_Ada.Skels;