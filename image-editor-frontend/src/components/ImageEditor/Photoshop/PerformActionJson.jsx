import { useState } from "react";
import { View, Text, TextField, Button, Image, Flex } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function PerformActionJson({ inputImageFile, originalImageId }) {
  const [outputImageUrl, setOutputImageUrl] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const { saveTransformedImage } = useSaveTransformedImage();

  const handlePerformActions = async () => {
    if (!inputImageFile) {
      setError("Please upload an image file.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_file", inputImageFile);

    try {
      const res = await fetch("http://localhost:3000/perform_action_json", {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Error performing Photoshop action.");
      } else {
        setOutputImageUrl(data.output_url);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!outputImageUrl || !originalImageId) return;
    setSaving(true);
    await saveTransformedImage(outputImageUrl, originalImageId);
    setSaving(false);
  };

  return (
    <View width="100%" marginTop="size-400">
      <Flex direction="column" alignItems="center" gap="size-200" maxWidth="500px" marginX="auto">

        <Button onPress={handlePerformActions} isDisabled={loading}>
          {loading ? "Processing..." : "Perform Actions"}
        </Button>

        {outputImageUrl && (
          <View marginTop="size-400" alignSelf="center">
            <Text>Processed Image:</Text>
            <Image
              src={outputImageUrl}
              alt="Processed Output"
              width="100%"
              objectFit="contain"
              marginTop="size-200"
            />
            <Button
              onPress={handleSave}
              isDisabled={saving}
              marginTop="size-200"
            >
              {saving ? "Saving..." : "Save Image"}
            </Button>
          </View>
        )}
      </Flex>
    </View>
  );
}