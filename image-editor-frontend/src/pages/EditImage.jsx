import { useState } from "react";
import { View, Flex } from "@adobe/react-spectrum";
import ImageUpload from "../components/ImageUpload";
import ImageEditor from "../components/ImageEditor/ImageEditor";

export default function EditImage({ imageUrl, setImageUrl }) { 
    const [uploadedImageId, setUploadedImageId] = useState(null); // ✅ Correctly store uploaded image ID
    const [originalImageId, setOriginalImageId] = useState(null);
    return (
      <View backgroundColor="gray-200" minHeight="100vh" width="100vw">
        <Flex direction="column" alignItems="center" gap="size-400" width="100%">
          <ImageUpload setImageUrl={setImageUrl} setUploadedImageId={setUploadedImageId} setOriginalImageId={setOriginalImageId}/>
          {imageUrl && <ImageEditor imageUrl={imageUrl} uploadedImageId={uploadedImageId} originalImageId={originalImageId}/>}
        </Flex>
      </View>
    );  
  }