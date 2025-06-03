import os
import re

def remove_comments_and_add_docs(code: str) -> str:
    # Remove existing comments
    code = re.sub(r'//.*', '', code)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    
    # Find all function declarations
    function_pattern = r'(static\s+)?(Future<.*?>|void|String|bool|int|double|Widget|BuildContext|Map<.*?>|List<.*?>|dynamic)\s+(\w+)\s*\([^)]*\)'
    
    def add_docstring(match):
        func_type = match.group(2)
        func_name = match.group(3)
        
        # Generate short description based on function name and type
        description = f"/// {func_name}: "
        
        if "is" in func_name or "has" in func_name or "can" in func_name:
            description += "Checks if "
        elif "get" in func_name:
            description += "Retrieves "
        elif "set" in func_name:
            description += "Sets "
        elif "create" in func_name:
            description += "Creates "
        elif "update" in func_name:
            description += "Updates "
        elif "delete" in func_name:
            description += "Deletes "
        elif "handle" in func_name:
            description += "Handles "
        elif "process" in func_name:
            description += "Processes "
        elif "validate" in func_name:
            description += "Validates "
        elif "show" in func_name:
            description += "Displays "
        else:
            description += "Performs "
            
        # Add return type context
        if "Future" in func_type:
            description += "asynchronously"
        elif func_type == "void":
            description += "without returning a value"
        elif func_type == "bool":
            description += "and returns a boolean result"
        elif func_type == "String":
            description += "and returns a string"
        elif "Map" in func_type:
            description += "and returns a map"
        elif "List" in func_type:
            description += "and returns a list"
        elif func_type == "Widget":
            description += "and returns a widget"
            
        return f"{description}\n{match.group(0)}"
    
    # Add docstrings to functions
    code = re.sub(function_pattern, add_docstring, code)
    
    # Clean up extra whitespace lines
    lines = [line.rstrip() for line in code.splitlines() if line.strip()]
    return '\n'.join(lines)

def process_dart_files(directory: str):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Process the file
                    cleaned_content = remove_comments_and_add_docs(content)
                    
                    # Write back to file
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(cleaned_content)
                    
                    print(f"Processed: {file_path}")
                except Exception as e:
                    print(f"Error processing {file_path}: {str(e)}")

if __name__ == "__main__":
    lib_dir = "lib"
    if os.path.exists(lib_dir):
        process_dart_files(lib_dir)
        print("Finished processing all Dart files in the lib directory")
    else:
        print(f"Error: {lib_dir} directory not found") 