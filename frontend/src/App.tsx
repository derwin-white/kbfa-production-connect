import { NavLink, Route, Routes } from "react-router-dom";
import { EntityDetailPage } from "./pages/EntityDetailPage";
import { ProjectDetailPage } from "./pages/ProjectDetailPage";
import { ProjectsPage } from "./pages/ProjectsPage";
import { SearchPage } from "./pages/SearchPage";

function App() {
  return (
    <div className="app-shell">
      <header className="app-header">
        <span className="app-header__wordmark">KBFA Production Connect</span>
        <nav>
          <NavLink to="/" end>
            Search
          </NavLink>
          <NavLink to="/projects">Projects</NavLink>
        </nav>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<SearchPage />} />
          <Route path="/entities/:entityId" element={<EntityDetailPage />} />
          <Route path="/projects" element={<ProjectsPage />} />
          <Route path="/projects/:projectId" element={<ProjectDetailPage />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
