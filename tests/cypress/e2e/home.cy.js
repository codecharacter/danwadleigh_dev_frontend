const RESUME_URL = "https://danwadleigh.dev/"
const API_URL = "https://danwadleigh.dev/api/visits"

describe('AWS Cloud Resume Challenge - Frontend Tests', () => {
  it("Open resume website", () => {
    cy.visit(RESUME_URL)
    cy.contains("dan@codecharacter.dev")
    cy.contains("@DanWadleigh")
    cy.contains("CodeCharacter.dev")
    cy.contains("Cloud Resume Challenge")
  })

  it('Test API Endpoint Response', () => {
    cy.request(API_URL).then((response) => {
      expect(response.status).to.equal(200)
      
      /*const counterValue = parseInt(response.body) */
      expect(response.body).to.be.a("number")
   })
  })

  it("Test visitor_count increments by 1", () => {
    let visitorCounter;
    let updatedVisitorCounter;
    cy.request(API_URL).then((response) => {
      visitorCounter = parseInt(response.body)
    })
    cy.request(API_URL).then((response) => {
      updatedVisitorCounter = parseInt(response.body)
      expect(updatedVisitorCounter).to.be.greaterThan(
        parseInt(visitorCounter)
      )
      expect(updatedVisitorCounter).to.be.equal(
        parseInt((visitorCounter) + 1)
      )
    })
  })
})