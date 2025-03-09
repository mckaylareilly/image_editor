import { Heading, View, Flex } from "@adobe/react-spectrum";
import { Link } from "react-router-dom";

export default function Header() {
  return (
    <View 
      paddingY="size-100" 
      width="100vw" 
      marginBottom="size-400"
      UNSAFE_style={{ 
        backgroundColor: "#580F19", 
        boxShadow: "0px 4px 10px rgba(0, 0, 0, 0.1)",
        color: "white",
        textAlign: "left", 
        paddingLeft: "1rem" 
      }}
    >
      <Flex alignItems="center" gap="size-200" justifyContent="flex-start">
        <Heading level={2} UNSAFE_style={{ margin: 0, color: "white" }}>
          Image Editor
        </Heading>
        <Link 
          to="/" 
          style={{ 
            color: "white", 
            textDecoration: "none", 
            fontSize: "18px",
            padding: "4px 10px",  
            borderRadius: "4px",
            marginLeft: "10px"  
          }}
        >
          Edit an Image
        </Link>
        <Link 
          to="/library" 
          style={{ 
            color: "white", 
            textDecoration: "none", 
            fontSize: "18px",
            padding: "4px 10px",  
            borderRadius: "4px",
            marginLeft: "10px" 
          }}
        >
          Library
        </Link>
      </Flex>
    </View>
  );
}