import { useState } from "react";
import { View, Text, TextField, Button, Image, Flex } from "@adobe/react-spectrum";
import ActionsUpload from "./ActionsUpload";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function PerformActions({ imageUrl, setImageUrl, inputImageFile, originalImageId }) {
  const [actionsFile, setActionsFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const { saveTransformedImage } = useSaveTransformedImage();

  const handlePerformActions = async () => {
    if (!inputImageFile || !actionsFile) {
      setError("Please upload both an image and a .atn file.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_file", inputImageFile);
    formData.append("actions_file", actionsFile);

    try {
      const res = await fetch("http://localhost:3000/perform_actions", {
        method: "POST",
        body: formData,
        credentials: 'include',
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Error performing Photoshop action.");
      } else {
        setImageUrl(data.output_url);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!imageUrl || !originalImageId) return;
    await saveTransformedImage(imageUrl, originalImageId);
  };

  return (
    <View width="100%" marginTop="size-400">
      <Flex direction="column" alignItems="center" gap="size-200" maxWidth="500px" marginX="auto">
        <ActionsUpload setActionsFile={setActionsFile} />

        {actionsFile && (
          <TextField label="Selected Action File" isReadOnly value={actionsFile.name} />
        )}

        {error && <Text color="negative">{error}</Text>}

        <Button onPress={handlePerformActions} isDisabled={loading}>
          {loading ? "Processing..." : "Perform Actions"}
        </Button>

   
          <View marginTop="size-400" alignSelf="center">
            <Button
              onPress={handleSave}
              marginTop="size-200"
            >
              {"Save Image"}
            </Button>
          </View>
      </Flex>
    </View>
  );
}