import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { useState, useEffect } from 'react'
import { Provider, defaultTheme, View } from "@adobe/react-spectrum";
import EditImage from './pages/EditImage';
import Library from './pages/Library';
import Header from './components/Header';
import './App.css'

function App() {
  const [imageUrl, setImageUrl] = useState(null);

  return (
    <>
    <Provider theme={defaultTheme} colorScheme="light">
      <Router>
        <View backgroundColor="gray-200" minHeight="100vh" width="100vw">
          <Header />
          <Routes>
            <Route path="/" element={<EditImage imageUrl={imageUrl} setImageUrl={setImageUrl} />} />
            <Route path="/library" element={<Library />} />
          </Routes>
        </View>
      </Router>
    </Provider>
    </> 
  )
}

export default App