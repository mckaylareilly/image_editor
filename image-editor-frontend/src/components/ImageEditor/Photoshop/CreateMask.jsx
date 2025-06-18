import { useState } from "react";
import { View, Text, TextField, Button, Image, Flex } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function CreateMask({ setImageUrl, inputImageFile, originalImageId }) {
  const [outputImageUrl, setOutputImageUrl] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const handleRemoveBackground = async () => {
    if (!inputImageFile) {
      setError("Please upload an image file.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_file", inputImageFile);

    try {
      const res = await fetch("http://localhost:3000/create_mask", {
        method: "POST",
        body: formData,
        credentials: 'include',
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Error performing Photoshop Remove Background.");
      } else {
        setImageUrl(data.output_url);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View width="100%" marginTop="size-400">
      <Flex direction="column" alignItems="center" gap="size-200" maxWidth="500px" marginX="auto">

        <Button onPress={handleRemoveBackground} isDisabled={loading}>
          {loading ? "Processing..." : "Create Mask"}
        </Button>
      </Flex>
    </View>
  );
}