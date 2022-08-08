(function_declaration
  (identifier) @func.name
  (parameter_list
      (parameter_declaration
          (identifier) @param.name
          ("," @param.separator (_))*
          (qualified_type (package_identifier (type_identifier))) @param.type
          )))
