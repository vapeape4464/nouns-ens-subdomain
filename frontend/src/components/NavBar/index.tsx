//// *** Uncomment all the code here to add the ability to login with wallet
//// *** in case you want to interact with smart contracts

import { Container, Nav, Navbar } from "react-bootstrap";
// import { LinkContainer } from "react-router-bootstrap";
export const NavBar = () => {
  return (
    <Navbar collapseOnSelect bg="dark" variant="dark" expand="lg">
      <Container fluid>
        <Navbar.Brand href="/">Subdomain Registrar</Navbar.Brand>
        <Navbar.Toggle aria-controls="responsive-navbar-nav" />
        {/* <Navbar.Collapse id="responsive-navbar-nav">
          <Nav className="me-auto">
            <LinkContainer to="/">
              <Nav.Link>Expiring Soon!</Nav.Link>
            </LinkContainer>
            <LinkContainer to="/search">
              <Nav.Link>Search</Nav.Link>
            </LinkContainer>
          </Nav>
        </Navbar.Collapse> */}
      </Container>
    </Navbar>
  );
};
