import { Heading, View, FileTrigger, Button, Flex, Text } from "@adobe/react-spectrum";
import { useState } from "react";

export default function ActionsUpload({ setActionsFile }) {
  const [uploadSuccess, setUploadSuccess] = useState(null);
  const [errorMessage, setErrorMessage] = useState("");

  const handleFileUpload = (files) => {
    if (files.length === 0) return;

    const file = files[0];

    if (!file.name.endsWith(".atn")) {
      setErrorMessage("Only .atn files are allowed.");
      setUploadSuccess(false);
      return;
    }

    setActionsFile(file);
    setUploadSuccess(true);
    setErrorMessage("");
  };

  return (
    <View
      backgroundColor="gray-100"
      padding="size-200"
      borderBottomWidth="thin"
      borderColor="gray-300"
      borderRadius="medium"
      marginBottom="size-400"
      marginTop="size-400"
      UNSAFE_style={{
        boxShadow: "0px 4px 10px rgba(0, 0, 0, 0.1)",
        margin: "0 auto",
      }}
    >
      <Flex direction="column" alignItems="center" justifyContent="center" gap="size-200">
        <Heading level={3}>Upload Photoshop Actions (.atn)</Heading>
        <FileTrigger onSelect={handleFileUpload} accepts={[".atn"]}>
          <Button
            variant="accent"
            UNSAFE_style={{
              backgroundColor: "#C8102E",
              color: "white",
            }}
          >
            Select .atn File
          </Button>
        </FileTrigger>
        <Text>Click the button to select a .atn file.</Text>
        {uploadSuccess === true && <Text>Action file selected successfully!</Text>}
        {uploadSuccess === false && <Text color="negative">Failed to select action file.</Text>}
        {errorMessage && <Text color="negative">{errorMessage}</Text>}
      </Flex>
    </View>
  );
}