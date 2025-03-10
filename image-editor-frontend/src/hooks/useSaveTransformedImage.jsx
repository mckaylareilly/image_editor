import { useState } from "react";

export default function useSaveTransformedImage() {
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState(null);

  const saveTransformedImage = async (transformedImageUrl, originalImageId) => {
    if (!transformedImageUrl) {
      console.error("No transformed image URL to save.");
      return;
    }

    if (!originalImageId) {
      console.error("No original image ID found.");
      return;
    }

    setIsSaving(true);

    try {
      const response = await fetch("http://localhost:3000/transformed_images", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          transformed_image: {
            file: transformedImageUrl,
            image_id: originalImageId,
          },
        }),
      });

      if (!response.ok) throw new Error("Failed to save image");

      alert("Image saved successfully!");
    } catch (error) {
      setError(`Error saving image: ${error.message}`);
    } finally {
      setIsSaving(false);
    }
  };

  return { saveTransformedImage, isSaving, error };
}