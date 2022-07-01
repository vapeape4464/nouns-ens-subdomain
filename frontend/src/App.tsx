import { Routes, Route } from "react-router";
import { NavBar } from "./components/NavBar";
import { RegistrarPage } from "./pages/RegistrarPage";

function App() {
  return (
    <>
      <NavBar />
      <>
        <Routes>
          <Route path="/" element={<RegistrarPage />} />
        </Routes>
      </>
    </>
  );
}

export default App;
